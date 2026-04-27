//
//  LoginViewModel.swift
//  Polaris
//
//  Created by Codex on 4/26/26.
//

import Foundation

@MainActor
final class LoginViewModel {
    struct State: Equatable {
        var isLoading = false
        var errorMessage: String?
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let authRepository: any AuthRepository
    private var pendingLoginRequest: AuthLoginRequest?
    private(set) var state = State()

    init(authRepository: any AuthRepository) {
        self.authRepository = authRepository
    }

    func prepareKakaoLogin() async -> AuthLoginRequest? {
        guard state.isLoading == false else { return nil }

        updateState(isLoading: true, errorMessage: nil)

        do {
            let request = try await authRepository.makeKakaoLoginRequest()
            pendingLoginRequest = request
            return request
        } catch {
            pendingLoginRequest = nil
            updateState(isLoading: false, errorMessage: "로그인 요청을 만들지 못했습니다.")
            return nil
        }
    }

    func completeLogin(callbackURL: URL) async {
        guard let pendingLoginRequest else {
            updateState(isLoading: false, errorMessage: "로그인 요청 상태를 찾지 못했습니다.")
            return
        }

        guard callbackURL.scheme == pendingLoginRequest.callbackScheme else {
            self.pendingLoginRequest = nil
            updateState(isLoading: false, errorMessage: errorMessage(for: AuthError.invalidCallback))
            return
        }

        do {
            let callback = try AuthCallback(url: callbackURL)
            _ = try await authRepository.exchange(
                code: callback.code,
                targetID: callback.targetID,
                codeVerifier: pendingLoginRequest.codeVerifier
            )
            self.pendingLoginRequest = nil
            updateState(isLoading: false, errorMessage: nil)
            onRoute?(.home)
        } catch {
            self.pendingLoginRequest = nil
            updateState(isLoading: false, errorMessage: errorMessage(for: error))
        }
    }

    func didCancelExternalLogin() {
        pendingLoginRequest = nil
        updateState(isLoading: false, errorMessage: nil)
    }

    func didFailExternalLogin() {
        pendingLoginRequest = nil
        updateState(isLoading: false, errorMessage: "카카오 로그인 화면을 열지 못했습니다.")
    }

    func didTapBack() {
        pendingLoginRequest = nil
        updateState(isLoading: false, errorMessage: nil)
        onRoute?(.back)
    }

    private func updateState(isLoading: Bool, errorMessage: String?) {
        state.isLoading = isLoading
        state.errorMessage = errorMessage
        onStateChange?(state)
    }

    private func errorMessage(for error: Error) -> String {
        guard let authError = error as? AuthError else {
            return "로그인 중 오류가 발생했습니다."
        }

        switch authError {
        case .invalidCallback:
            return "로그인 응답 URL이 올바르지 않습니다."
        case .missingAuthorizationCode:
            return "로그인 인증 코드를 찾지 못했습니다."
        case .missingTargetID:
            return "로그인 대상 정보를 찾지 못했습니다."
        case .httpStatus(let statusCode):
            return "로그인 요청이 실패했습니다. 상태 코드 \(statusCode)"
        case .networkFailure:
            return "네트워크 연결을 확인해주세요."
        case .decodingFailure:
            return "로그인 응답을 해석하지 못했습니다."
        case .invalidLoginURL, .missingPendingLogin, .missingRefreshToken:
            return "로그인 상태를 다시 확인해주세요."
        }
    }
}

private struct AuthCallback {
    let code: String
    let targetID: String

    init(url: URL) throws {
        let queryItems = Self.queryItems(from: url)
        guard queryItems.isEmpty == false else {
            throw AuthError.invalidCallback
        }

        guard let code = queryItems["code"], code.isEmpty == false else {
            throw AuthError.missingAuthorizationCode
        }

        guard let targetID = queryItems["targetId"] ?? queryItems["target_id"],
              targetID.isEmpty == false else {
            throw AuthError.missingTargetID
        }

        self.code = code
        self.targetID = targetID
    }

    private static func queryItems(from url: URL) -> [String: String] {
        var values: [String: String] = [:]

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            for item in components.queryItems ?? [] {
                values[item.name] = item.value
            }
        }

        if let fragment = url.fragment,
           let fragmentComponents = URLComponents(string: "callback?\(fragment)") {
            for item in fragmentComponents.queryItems ?? [] {
                values[item.name] = item.value
            }
        }

        return values
    }
}
