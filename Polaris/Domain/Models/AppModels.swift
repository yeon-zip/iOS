//
//  AppModels.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum DistanceOption: String, CaseIterable, Hashable, Sendable {
    case twoKm = "2km"
    case fiveKm = "5km"
    case tenKm = "10km"
}

enum OperatingStatus: Hashable, Sendable {
    case open
    case closed

    var title: String {
        switch self {
        case .open:
            "운영중"
        case .closed:
            "운영 종료"
        }
    }
}

enum LoanStatus: Hashable, Sendable {
    case available
    case borrowed
    case notificationReady

    var title: String {
        switch self {
        case .available:
            "대출 가능"
        case .borrowed:
            "대출중"
        case .notificationReady:
            "알림 설정"
        }
    }
}

enum FavoriteTab: Int, CaseIterable, Hashable, Sendable {
    case books
    case libraries

    var title: String {
        switch self {
        case .books:
            "도서"
        case .libraries:
            "도서관"
        }
    }
}

enum AlertSection: Int, CaseIterable, Hashable, Sendable {
    case available
    case waiting

    var title: String {
        switch self {
        case .available:
            "대출 가능"
        case .waiting:
            "대기중"
        }
    }
}

struct SearchQuery: Hashable, Sendable {
    var text: String
    var excludeUnavailable: Bool
}

struct AddressSuggestion: Identifiable, Hashable, Sendable {
    let id: String
    let roadAddress: String
    let detailText: String
    let latitude: Double?
    let longitude: Double?
}

struct BadgeContent: Hashable, Sendable {
    enum Tone: Hashable, Sendable {
        case blue
        case green
        case red
        case yellow
        case gray
    }

    let title: String
    let tone: Tone

    static func == (lhs: BadgeContent, rhs: BadgeContent) -> Bool {
        lhs.title == rhs.title && lhs.tone == rhs.tone
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(tone)
    }
}

struct BookSummary: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let author: String
    let publisher: String
    let year: String
    let coverImageURL: URL?
    let isFavorite: Bool
    let isAlertEnabled: Bool
    let loanStatus: LoanStatus?
}

struct BookDetail: Hashable, Sendable {
    let id: String
    let title: String
    let author: String
    let publisher: String
    let year: String
    let coverImageURL: URL?
    let summary: String
    let isFavorite: Bool
}

struct LibrarySummary: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let distanceText: String
    let operatingStatus: OperatingStatus
    let loanStatus: LoanStatus?
    let isFavorite: Bool
    let isAlertEnabled: Bool
}

struct OperatingHour: Hashable, Sendable {
    let day: String
    let hoursText: String
    let isClosed: Bool
}

struct HolidayEntry: Hashable, Sendable {
    let title: String
}

struct LibraryDetail: Hashable, Sendable {
    let id: String
    let name: String
    let address: String
    let phone: String
    let latitude: Double?
    let longitude: Double?
    let hours: [OperatingHour]
    let regularHolidays: [HolidayEntry]
    let upcomingHolidays: [HolidayEntry]
    let mapDescription: String
}

struct AlertItem: Identifiable, Hashable, Sendable {
    let id: String
    let section: AlertSection
    let book: BookSummary
    let libraryName: String
}

struct UserProfile: Hashable, Sendable {
    let id: String
    let provider: String
    let role: String
    let nickname: String
    let email: String
    let profileImageURL: URL?
}

struct AuthSession: Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userId: Int64

    func isAccessTokenValid(now: Date = Date(), leeway: TimeInterval = 30) -> Bool {
        expiresAt.timeIntervalSince(now) > leeway
    }
}

struct AuthLoginRequest: Equatable, Sendable {
    let url: URL
    let codeVerifier: String
    let callbackScheme: String
}

enum AuthError: Error, Equatable {
    case invalidLoginURL
    case invalidCallback
    case missingAuthorizationCode
    case missingTargetID
    case missingPendingLogin
    case missingRefreshToken
    case httpStatus(Int)
    case networkFailure
    case decodingFailure
}
