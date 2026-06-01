//
//  AppDependencies.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum AppEnvironment: String {
    case live
    case mock

    static var current: AppEnvironment {
        let processInfo = ProcessInfo.processInfo

        if let rawValue = processInfo.environment["POLARIS_ENV"]?.lowercased(),
           let environment = AppEnvironment(rawValue: rawValue) {
            return environment
        }

        if processInfo.arguments.contains("-useMockData") {
            return .mock
        }

        return .live
    }
}

struct AppDependencies {
    let searchRepository: any SearchRepository
    let bookRepository: any BookRepository
    let bookVoteRepository: any BookVoteRepository
    let libraryRepository: any LibraryRepository
    let favoritesRepository: any FavoritesRepository
    let alertsRepository: any AlertsRepository
    let pushNotificationRepository: any PushNotificationRepository
    let profileRepository: any ProfileRepository
    let authRepository: any AuthRepository
    let locationAddressService: any LocationAddressService

    static let live: AppDependencies = {
        let apiClient = PolarisAPIClient()
        let authRepository = LiveAuthRepository()
        return AppDependencies(
            searchRepository: LiveSearchRepository(apiClient: apiClient),
            bookRepository: LiveBookRepository(apiClient: apiClient),
            bookVoteRepository: LiveBookVoteRepository(apiClient: apiClient, authRepository: authRepository),
            libraryRepository: LiveLibraryRepository(apiClient: apiClient),
            favoritesRepository: LiveFavoritesRepository(apiClient: apiClient, authRepository: authRepository),
            alertsRepository: LiveAlertsRepository(apiClient: apiClient, authRepository: authRepository),
            pushNotificationRepository: LivePushNotificationRepository(apiClient: apiClient, authRepository: authRepository),
            profileRepository: LiveProfileRepository(apiClient: apiClient, authRepository: authRepository),
            authRepository: authRepository,
            locationAddressService: AppleLocationAddressService()
        )
    }()

    static let mock = AppDependencies(
        searchRepository: MockSearchRepository(),
        bookRepository: MockBookRepository(),
        bookVoteRepository: MockBookVoteRepository(),
        libraryRepository: MockLibraryRepository(),
        favoritesRepository: MockFavoritesRepository(),
        alertsRepository: MockAlertsRepository(),
        pushNotificationRepository: MockPushNotificationRepository(),
        profileRepository: MockProfileRepository(),
        authRepository: MockAuthRepository(
            session: AuthSession(
                accessToken: "mock-access-token",
                refreshToken: "mock-refresh-token",
                expiresAt: Date().addingTimeInterval(600),
                userId: 1
            )
        ),
        locationAddressService: AppleLocationAddressService()
    )

    static func make(for environment: AppEnvironment = .current) -> AppDependencies {
        switch environment {
        case .live:
            return .live
        case .mock:
            return .mock
        }
    }
}
