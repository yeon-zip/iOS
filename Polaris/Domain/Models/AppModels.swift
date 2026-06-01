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

enum BookVoteType: String, Codable, Hashable, Sendable {
    case recommend = "RECOMMEND"
    case notRecommend = "NOT_RECOMMEND"

    var title: String {
        switch self {
        case .recommend:
            "추천"
        case .notRecommend:
            "비추천"
        }
    }
}

struct BookVoteSummary: Hashable, Sendable {
    let recommendCount: Int
    let notRecommendCount: Int
    let myVote: BookVoteType?

    var totalCount: Int {
        recommendCount + notRecommendCount
    }

    static let empty = BookVoteSummary(recommendCount: 0, notRecommendCount: 0, myVote: nil)

    func applying(_ voteType: BookVoteType) -> BookVoteSummary {
        guard voteType == .recommend, myVote != .recommend else { return self }

        var nextRecommendCount = recommendCount
        var nextNotRecommendCount = notRecommendCount

        if myVote == .notRecommend {
            nextNotRecommendCount = max(0, nextNotRecommendCount - 1)
        }

        nextRecommendCount += 1

        return BookVoteSummary(
            recommendCount: nextRecommendCount,
            notRecommendCount: nextNotRecommendCount,
            myVote: voteType
        )
    }
}

enum AlertSection: Int, CaseIterable, Hashable, Sendable {
    case available
    case waiting

    var title: String {
        switch self {
        case .available:
            "대출 가능 알림"
        case .waiting:
            "알림 신청 목록"
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

extension AddressSuggestion {
    static let defaultLocation = AddressSuggestion(
        id: "kumoh-national-institute-of-technology",
        roadAddress: "경상북도 구미시 대학로 61",
        detailText: "국립금오공과대학교",
        latitude: 36.1450,
        longitude: 128.3937
    )
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
    let voteSummary: BookVoteSummary
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
    let voteSummary: BookVoteSummary
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
    let libraryID: String
    let libraryName: String
    let message: String?
    let createdAt: String?

    init(
        id: String,
        section: AlertSection,
        book: BookSummary,
        libraryID: String,
        libraryName: String,
        message: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.section = section
        self.book = book
        self.libraryID = libraryID
        self.libraryName = libraryName
        self.message = message
        self.createdAt = createdAt
    }
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
