//
//  LiveAuthRepository.swift
//  Polaris
//
//  Created by Codex on 4/26/26.
//

import Foundation

actor LiveAuthRepository: AuthRepository {
    private enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    private struct AuthExchangeRequest: Encodable {
        let code: String
        let targetId: String
        let codeVerifier: String
    }

    private struct AuthTokenResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int64
        let userId: Int64
    }

    private let session: URLSession
    private let baseURL: URL
    private let appScheme: String
    private let refreshTokenStore: any RefreshTokenStore
    private let pkceGenerator: any PKCEGenerating
    private var cachedSession: AuthSession?

    init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://api.k-polaris.life/api/v1")!,
        appScheme: String = "polaris",
        refreshTokenStore: any RefreshTokenStore = KeychainRefreshTokenStore(),
        pkceGenerator: any PKCEGenerating = SecurePKCEGenerator()
    ) {
        self.session = session
        self.baseURL = baseURL
        self.appScheme = appScheme
        self.refreshTokenStore = refreshTokenStore
        self.pkceGenerator = pkceGenerator
    }

    func currentSession() async -> AuthSession? {
        cachedSession
    }

    func restoreSession() async -> AuthSession? {
        if let cachedSession, cachedSession.isAccessTokenValid() {
            return cachedSession
        }

        guard (try? await refreshTokenStore.loadRefreshToken()) != nil else {
            return nil
        }

        do {
            return try await refresh()
        } catch AuthError.httpStatus(let statusCode) where [400, 401, 403].contains(statusCode) {
            await clearLocalSession()
            return nil
        } catch {
            return nil
        }
    }

    func makeKakaoLoginRequest() async throws -> AuthLoginRequest {
        let challenge = try pkceGenerator.makeChallenge()
        var components = URLComponents(
            url: baseURL.appendingPathComponent("auth/kakao/login"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "channel", value: "app"),
            URLQueryItem(name: "target", value: appScheme),
            URLQueryItem(name: "codeChallenge", value: challenge.codeChallenge),
            URLQueryItem(name: "codeChallengeMethod", value: challenge.method)
        ]

        guard let url = components?.url else {
            throw AuthError.invalidLoginURL
        }

        return AuthLoginRequest(
            url: url,
            codeVerifier: challenge.codeVerifier,
            callbackScheme: appScheme
        )
    }

    func exchange(code: String, targetID: String, codeVerifier: String) async throws -> AuthSession {
        let body = AuthExchangeRequest(
            code: code,
            targetId: targetID,
            codeVerifier: codeVerifier
        )
        let response: AuthTokenResponse = try await sendJSON(
            path: "auth/exchange",
            method: .post,
            body: body
        )
        return try await saveTokenResponse(response)
    }

    func refresh() async throws -> AuthSession {
        let refreshToken = try await refreshTokenStore.loadRefreshToken() ?? cachedSession?.refreshToken
        guard let refreshToken, refreshToken.isEmpty == false else {
            throw AuthError.missingRefreshToken
        }

        do {
            let response: AuthTokenResponse = try await send(
                path: "auth/refresh",
                method: .post,
                headers: ["Authorization": "Bearer \(refreshToken)"]
            )
            return try await saveTokenResponse(response)
        } catch AuthError.httpStatus(let statusCode) where [400, 401, 403].contains(statusCode) {
            let response: AuthTokenResponse = try await send(
                path: "auth/refresh",
                method: .post,
                headers: ["Authorization": refreshToken]
            )
            return try await saveTokenResponse(response)
        }
    }

    func logout() async throws {
        let session = cachedSession
        await clearLocalSession()

        guard let session else { return }

        try? await sendVoid(
            path: "auth/logout",
            method: .delete,
            headers: [
                "Authorization": "Bearer \(session.accessToken)",
                "Refresh-Token": session.refreshToken
            ]
        )
    }

    func clearLocalSession() async {
        cachedSession = nil
        try? await refreshTokenStore.clearRefreshToken()
    }

    private func saveTokenResponse(_ response: AuthTokenResponse) async throws -> AuthSession {
        let session = AuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn)),
            userId: response.userId
        )
        cachedSession = session
        try await refreshTokenStore.saveRefreshToken(response.refreshToken)
        return session
    }

    private func sendJSON<Response: Decodable, Body: Encodable>(
        path: String,
        method: HTTPMethod,
        body: Body,
        headers: [String: String] = [:]
    ) async throws -> Response {
        var request = try makeRequest(path: path, method: method, headers: headers)
        request.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await perform(request)
    }

    private func send<Response: Decodable>(
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let request = try makeRequest(path: path, method: method, headers: headers)
        return try await perform(request)
    }

    private func sendVoid(
        path: String,
        method: HTTPMethod,
        headers: [String: String] = [:]
    ) async throws {
        let request = try makeRequest(path: path, method: method, headers: headers)
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkFailure
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw AuthError.httpStatus(httpResponse.statusCode)
        }
    }

    private func makeRequest(
        path: String,
        method: HTTPMethod,
        headers: [String: String]
    ) throws -> URLRequest {
        let sanitizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(sanitizedPath)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        headers.forEach { name, value in
            request.setValue(value, forHTTPHeaderField: name)
        }
        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AuthError.networkFailure
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkFailure
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw AuthError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw AuthError.decodingFailure
        }
    }
}

actor MockAuthRepository: AuthRepository {
    private var session: AuthSession?

    init(session: AuthSession? = nil) {
        self.session = session
    }

    func currentSession() async -> AuthSession? {
        session
    }

    func restoreSession() async -> AuthSession? {
        session
    }

    func makeKakaoLoginRequest() async throws -> AuthLoginRequest {
        AuthLoginRequest(
            url: URL(string: "https://api.k-polaris.life/api/v1/auth/kakao/login?channel=app&target=polaris&codeChallenge=mock&codeChallengeMethod=S256")!,
            codeVerifier: "mock-code-verifier",
            callbackScheme: "polaris"
        )
    }

    func exchange(code: String, targetID: String, codeVerifier: String) async throws -> AuthSession {
        let session = AuthSession(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            expiresAt: Date().addingTimeInterval(600),
            userId: 1
        )
        self.session = session
        return session
    }

    func refresh() async throws -> AuthSession {
        if let session {
            return session
        }
        throw AuthError.missingRefreshToken
    }

    func logout() async throws {
        session = nil
    }

    func clearLocalSession() async {
        session = nil
    }
}
