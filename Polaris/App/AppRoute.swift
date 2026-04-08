//
//  AppRoute.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum AppRoute: Hashable {
    case home
    case search(currentLocation: AddressSuggestion, currentDistance: DistanceOption, initialQuery: String?)
    case bookSearch(query: String)
    case likes
    case alerts
    case profile
    case login
    case locationPicker(currentLocation: AddressSuggestion)
    case libraryDetail(id: String)
    case bookDetail(id: String)
    case back
}
