//
//  AppDependencies.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum AppEnvironment: String {
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

        return .mock
    }
}

struct AppDependencies {
    let searchRepository: any SearchRepository
    let bookRepository: any BookRepository
    let libraryRepository: any LibraryRepository
    let favoritesRepository: any FavoritesRepository
    let alertsRepository: any AlertsRepository
    let profileRepository: any ProfileRepository

    static let mock = AppDependencies(
        searchRepository: MockSearchRepository(),
        bookRepository: MockBookRepository(),
        libraryRepository: MockLibraryRepository(),
        favoritesRepository: MockFavoritesRepository(),
        alertsRepository: MockAlertsRepository(),
        profileRepository: MockProfileRepository()
    )

    static func make(for environment: AppEnvironment = .current) -> AppDependencies {
        switch environment {
        case .mock:
            return .mock
        }
    }
}
