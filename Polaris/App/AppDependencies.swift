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
    let libraryRepository: any LibraryRepository
    let favoritesRepository: any FavoritesRepository
    let alertsRepository: any AlertsRepository
    let profileRepository: any ProfileRepository
    let authRepository: any AuthRepository
    let locationAddressService: any LocationAddressService

    static let live: AppDependencies = {
        let apiClient = PolarisAPIClient()
        let authRepository = LiveAuthRepository()
        return AppDependencies(
            searchRepository: LiveSearchRepository(apiClient: apiClient),
            bookRepository: LiveBookRepository(apiClient: apiClient),
            libraryRepository: LiveLibraryRepository(apiClient: apiClient),
            favoritesRepository: LiveFavoritesRepository(apiClient: apiClient, authRepository: authRepository),
            alertsRepository: UnavailableAlertsRepository(),
            profileRepository: LiveProfileRepository(apiClient: apiClient, authRepository: authRepository),
            authRepository: authRepository,
            locationAddressService: AppleLocationAddressService()
        )
    }()

    static let mock = AppDependencies(
        searchRepository: MockSearchRepository(),
        bookRepository: MockBookRepository(),
        libraryRepository: MockLibraryRepository(),
        favoritesRepository: MockFavoritesRepository(),
        alertsRepository: MockAlertsRepository(),
        profileRepository: MockProfileRepository(),
        authRepository: MockAuthRepository(),
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
