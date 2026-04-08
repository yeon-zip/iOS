//
//  CommonViewData.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

struct BookCarouselItemViewData: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let coverImageURL: URL?
    let isFeatured: Bool
    let isSelected: Bool

    static func == (lhs: BookCarouselItemViewData, rhs: BookCarouselItemViewData) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.coverImageURL == rhs.coverImageURL &&
        lhs.isFeatured == rhs.isFeatured &&
        lhs.isSelected == rhs.isSelected
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(coverImageURL)
        hasher.combine(isFeatured)
        hasher.combine(isSelected)
    }
}

struct LibraryCardItemViewData: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let distanceText: String
    let badges: [BadgeContent]
    let showsBell: Bool
    let showsFavorite: Bool
    let isBellActive: Bool
    let isFavorite: Bool

    static func == (lhs: LibraryCardItemViewData, rhs: LibraryCardItemViewData) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.distanceText == rhs.distanceText &&
        lhs.badges == rhs.badges &&
        lhs.showsBell == rhs.showsBell &&
        lhs.showsFavorite == rhs.showsFavorite &&
        lhs.isBellActive == rhs.isBellActive &&
        lhs.isFavorite == rhs.isFavorite
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(distanceText)
        hasher.combine(badges)
        hasher.combine(showsBell)
        hasher.combine(showsFavorite)
        hasher.combine(isBellActive)
        hasher.combine(isFavorite)
    }
}

struct FavoriteBookItemViewData: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let coverImageURL: URL?
    let badges: [BadgeContent]
    let isAlertEnabled: Bool
    let isFavorite: Bool

    static func == (lhs: FavoriteBookItemViewData, rhs: FavoriteBookItemViewData) -> Bool {
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.subtitle == rhs.subtitle &&
        lhs.coverImageURL == rhs.coverImageURL &&
        lhs.badges == rhs.badges &&
        lhs.isAlertEnabled == rhs.isAlertEnabled &&
        lhs.isFavorite == rhs.isFavorite
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(coverImageURL)
        hasher.combine(badges)
        hasher.combine(isAlertEnabled)
        hasher.combine(isFavorite)
    }
}

struct AlertBookItemViewData: Identifiable, Hashable, Sendable {
    let id: String
    let bookID: String
    let title: String
    let metadataText: String
    let libraryName: String
    let badges: [BadgeContent]
    let isAlertEnabled: Bool

    static func == (lhs: AlertBookItemViewData, rhs: AlertBookItemViewData) -> Bool {
        lhs.id == rhs.id &&
        lhs.bookID == rhs.bookID &&
        lhs.title == rhs.title &&
        lhs.metadataText == rhs.metadataText &&
        lhs.libraryName == rhs.libraryName &&
        lhs.badges == rhs.badges &&
        lhs.isAlertEnabled == rhs.isAlertEnabled
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(bookID)
        hasher.combine(title)
        hasher.combine(metadataText)
        hasher.combine(libraryName)
        hasher.combine(badges)
        hasher.combine(isAlertEnabled)
    }
}

func makeOperatingBadge(_ status: OperatingStatus) -> BadgeContent {
    switch status {
    case .open:
        return BadgeContent(title: status.title, tone: .blue)
    case .closed:
        return BadgeContent(title: status.title, tone: .red)
    }
}

func makeLoanBadge(_ status: LoanStatus) -> BadgeContent {
    switch status {
    case .available:
        return BadgeContent(title: status.title, tone: .yellow)
    case .borrowed:
        return BadgeContent(title: status.title, tone: .gray)
    case .notificationReady:
        return BadgeContent(title: status.title, tone: .gray)
    }
}
