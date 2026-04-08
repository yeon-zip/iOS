//
//  AppRoute.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum AppRoute: Hashable {
    case search
    case likes
    case alerts
    case profile
    case locationPicker(currentLocation: AddressSuggestion)
    case libraryDetail(id: String)
    case bookDetail(id: String)
    case back
}
