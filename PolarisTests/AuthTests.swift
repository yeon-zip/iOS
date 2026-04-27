//
//  AuthTests.swift
//  PolarisTests
//
//  Created by Codex on 4/26/26.
//

import Foundation
import Testing
import UIKit
@testable import Polaris

private struct FixedPKCEGenerator: PKCEGenerating {
    let challenge: PKCEChallenge

    func makeChallenge() throws -> PKCEChallenge {
        challenge
    }
}

private actor RecordingAuthRepository: AuthRepository {
    struct ExchangeCall: Equatable {
        let code: String
        let targetID: String
        let codeVerifier: String
    }

    private let loginRequest: AuthLoginRequest
    private var session: AuthSession?
    private var exchangeCall: ExchangeCall?
    private var loginRequestCallCount = 0

    init(loginRequest: AuthLoginRequest) {
        self.loginRequest = loginRequest
    }

    func currentSession() async -> AuthSession? {
        session
    }

    func restoreSession() async -> AuthSession? {
        session
    }

    func makeKakaoLoginRequest() async throws -> AuthLoginRequest {
        loginRequestCallCount += 1
        return loginRequest
    }

    func exchange(code: String, targetID: String, codeVerifier: String) async throws -> AuthSession {
        exchangeCall = ExchangeCall(code: code, targetID: targetID, codeVerifier: codeVerifier)
        let session = AuthSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(600),
            userId: 42
        )
        self.session = session
        return session
    }

    func refresh() async throws -> AuthSession {
        guard let session else {
            throw AuthError.missingRefreshToken
        }
        return session
    }

    func logout() async throws {
        session = nil
    }

    func clearLocalSession() async {
        session = nil
    }

    func recordedExchangeCall() async -> ExchangeCall? {
        exchangeCall
    }

    func recordedLoginRequestCallCount() async -> Int {
        loginRequestCallCount
    }
}

struct AuthTests {
    @Test func authRepositoryBuildsKakaoLoginURLWithAppPKCEParameters() async throws {
        let repository = LiveAuthRepository(
            baseURL: URL(string: "https://api.k-polaris.life/api/v1")!,
            appScheme: "polaris",
            refreshTokenStore: InMemoryRefreshTokenStore(),
            pkceGenerator: FixedPKCEGenerator(
                challenge: PKCEChallenge(
                    codeVerifier: "fixed-verifier",
                    codeChallenge: "fixed-challenge",
                    method: "S256"
                )
            )
        )

        let request = try await repository.makeKakaoLoginRequest()
        let components = try #require(URLComponents(url: request.url, resolvingAgainstBaseURL: false))
        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { item in
            (item.name, item.value ?? "")
        })

        #expect(components.scheme == "https")
        #expect(components.host == "api.k-polaris.life")
        #expect(components.path == "/api/v1/auth/kakao/login")
        #expect(queryItems["channel"] == "app")
        #expect(queryItems["target"] == "polaris")
        #expect(queryItems["codeChallenge"] == "fixed-challenge")
        #expect(queryItems["codeChallengeMethod"] == "S256")
        #expect(request.codeVerifier == "fixed-verifier")
        #expect(request.callbackScheme == "polaris")
    }

    @MainActor
    @Test func loginViewModelExchangesCallbackCodeWithPendingVerifier() async throws {
        let authRepository = RecordingAuthRepository(
            loginRequest: AuthLoginRequest(
                url: URL(string: "https://api.k-polaris.life/api/v1/auth/kakao/login")!,
                codeVerifier: "pending-verifier",
                callbackScheme: "polaris"
            )
        )
        let viewModel = LoginViewModel(authRepository: authRepository)
        var routed: AppRoute?
        viewModel.onRoute = { route in
            routed = route
        }

        let request = await viewModel.prepareKakaoLogin()
        #expect(request?.codeVerifier == "pending-verifier")
        #expect(viewModel.state.isLoading == true)

        await viewModel.completeLogin(
            callbackURL: URL(string: "polaris://auth?code=authorization-code&targetId=target-id")!
        )

        let exchangeCall = await authRepository.recordedExchangeCall()
        #expect(exchangeCall?.code == "authorization-code")
        #expect(exchangeCall?.targetID == "target-id")
        #expect(exchangeCall?.codeVerifier == "pending-verifier")
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorMessage == nil)
        #expect(routed == .home)
    }

    @MainActor
    @Test func loginViewModelIgnoresRepeatedPreparationWhileLoading() async throws {
        let authRepository = RecordingAuthRepository(
            loginRequest: AuthLoginRequest(
                url: URL(string: "https://api.k-polaris.life/api/v1/auth/kakao/login")!,
                codeVerifier: "pending-verifier",
                callbackScheme: "polaris"
            )
        )
        let viewModel = LoginViewModel(authRepository: authRepository)

        let firstRequest = await viewModel.prepareKakaoLogin()
        let secondRequest = await viewModel.prepareKakaoLogin()
        let loginRequestCallCount = await authRepository.recordedLoginRequestCallCount()

        #expect(firstRequest?.codeVerifier == "pending-verifier")
        #expect(secondRequest == nil)
        #expect(loginRequestCallCount == 1)
    }

    @MainActor
    @Test func loginViewModelRejectsCallbackWithUnexpectedScheme() async throws {
        let authRepository = RecordingAuthRepository(
            loginRequest: AuthLoginRequest(
                url: URL(string: "https://api.k-polaris.life/api/v1/auth/kakao/login")!,
                codeVerifier: "pending-verifier",
                callbackScheme: "polaris"
            )
        )
        let viewModel = LoginViewModel(authRepository: authRepository)

        _ = await viewModel.prepareKakaoLogin()
        await viewModel.completeLogin(
            callbackURL: URL(string: "other-scheme://auth?code=authorization-code&targetId=target-id")!
        )

        let exchangeCall = await authRepository.recordedExchangeCall()
        #expect(exchangeCall == nil)
        #expect(viewModel.state.isLoading == false)
        #expect(viewModel.state.errorMessage == "로그인 응답 URL이 올바르지 않습니다.")
    }

    @MainActor
    @Test func appNavigatorStartsAtLoginWhenSessionDoesNotRestore() async throws {
        let navigationController = UINavigationController()
        let navigator = AppNavigator(
            navigationController: navigationController,
            dependencies: Self.makeDependencies(authRepository: MockAuthRepository())
        )

        navigator.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first is LoginViewController)
    }

    @MainActor
    @Test func appNavigatorStartsAtHomeWhenSessionRestores() async throws {
        let navigationController = UINavigationController()
        let navigator = AppNavigator(
            navigationController: navigationController,
            dependencies: Self.makeDependencies(
                authRepository: MockAuthRepository(session: Self.authSession())
            )
        )

        navigator.start()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first is HomeViewController)
    }

    @MainActor
    @Test func homeRouteReplacesLoginStack() async throws {
        let navigationController = UINavigationController()
        let dependencies = Self.makeDependencies(authRepository: MockAuthRepository(session: Self.authSession()))
        let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)
        let loginViewController = LoginViewController(
            viewModel: LoginViewModel(authRepository: dependencies.authRepository),
            navigator: navigator
        )
        navigationController.viewControllers = [loginViewController]

        navigator.handle(.home, from: loginViewController)
        let containsLoginViewController = navigationController.viewControllers.contains { viewController in
            viewController is LoginViewController
        }

        #expect(navigationController.viewControllers.count == 1)
        #expect(navigationController.viewControllers.first is HomeViewController)
        #expect(containsLoginViewController == false)
    }

    private static func authSession() -> AuthSession {
        AuthSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(600),
            userId: 42
        )
    }

    private static func makeDependencies(authRepository: any AuthRepository) -> AppDependencies {
        let mock = AppDependencies.mock
        return AppDependencies(
            searchRepository: mock.searchRepository,
            bookRepository: mock.bookRepository,
            libraryRepository: mock.libraryRepository,
            favoritesRepository: mock.favoritesRepository,
            alertsRepository: mock.alertsRepository,
            profileRepository: mock.profileRepository,
            authRepository: authRepository,
            locationAddressService: mock.locationAddressService
        )
    }
}
