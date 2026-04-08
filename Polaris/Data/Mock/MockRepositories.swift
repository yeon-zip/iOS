//
//  MockRepositories.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

private enum MockFixture {
    static let books: [BookSummary] = [
        BookSummary(id: "book-arond-1", title: "아몬드", author: "손원평", publisher: "창비", year: "2024", isFavorite: true, isAlertEnabled: true, loanStatus: .borrowed),
        BookSummary(id: "book-arond-2", title: "아몬드", author: "홍길동", publisher: "개발출판사", year: "2024", isFavorite: true, isAlertEnabled: false, loanStatus: .borrowed),
        BookSummary(id: "book-arond-3", title: "아몬드", author: "홍길동", publisher: "개발출판사", year: "2024", isFavorite: false, isAlertEnabled: false, loanStatus: nil)
    ]

    static let libraries: [LibrarySummary] = [
        LibrarySummary(id: "library-gangnam", name: "강남 도서관", address: "서울특별시 강남구 역삼동 123-45", phone: "02-1111-1111", distanceText: "0.5km", operatingStatus: .open, loanStatus: .borrowed, isFavorite: true, isAlertEnabled: true),
        LibrarySummary(id: "library-yeoksam", name: "역삼도서관", address: "서울특별시 강남구 역삼동 123-45", phone: "02-1111-1111", distanceText: "0.8km", operatingStatus: .closed, loanStatus: .available, isFavorite: true, isAlertEnabled: false),
        LibrarySummary(id: "library-daechi", name: "대치 도서관", address: "서울특별시 강남구 대치동 100-1", phone: "02-2222-2222", distanceText: "1.2km", operatingStatus: .open, loanStatus: .available, isFavorite: true, isAlertEnabled: false),
        LibrarySummary(id: "library-suseo", name: "수서 도서관", address: "서울특별시 강남구 수서동 11-7", phone: "02-3333-3333", distanceText: "2.4km", operatingStatus: .open, loanStatus: nil, isFavorite: false, isAlertEnabled: false)
    ]

    static let alerts: [AlertItem] = [
        AlertItem(id: "alert-1", section: .available, book: BookSummary(id: "alert-book-1", title: "아몬드", author: "김철수", publisher: "인사이트", year: "2024", isFavorite: true, isAlertEnabled: true, loanStatus: .available)),
        AlertItem(id: "alert-2", section: .waiting, book: BookSummary(id: "alert-book-2", title: "아몬드", author: "김철수", publisher: "인사이트", year: "2024", isFavorite: false, isAlertEnabled: true, loanStatus: .notificationReady))
    ]

    static let libraryDetail = LibraryDetail(
        id: "library-yeoksam",
        name: "역삼도서관",
        address: "서울특별시 강남구 역삼동 123-45",
        phone: "02-1111-1111",
        hours: [
            OperatingHour(day: "평일", hoursText: "09:00 - 20:00", isClosed: false),
            OperatingHour(day: "토요일", hoursText: "09:00 - 20:00", isClosed: false),
            OperatingHour(day: "일요일", hoursText: "휴관", isClosed: true)
        ],
        regularHolidays: [
            HolidayEntry(title: "매주 일요일"),
            HolidayEntry(title: "법정 공휴일")
        ],
        upcomingHolidays: [
            HolidayEntry(title: "매주 일요일"),
            HolidayEntry(title: "설 연휴")
        ],
        mapDescription: "지도 API 연동 예정"
    )

    static let bookDetail = BookDetail(
        id: "book-arond-2",
        title: "아몬드",
        author: "홍길동",
        publisher: "개발출판사",
        year: "2024",
        summary: "면접 준비생과 취업 준비생을 위한 실전 면접 가이드. 실제 면접 사례와 합격 노하우를 담아 인성 면접부터 실무 면접까지 한 권으로 정리한 목업 설명입니다."
    )

    static let profile = UserProfile(
        name: "손유나",
        subtitle: "Polaris Demo",
        headline: "차분한 탐색 경험과 빠른 정보 접근을 위한 목업 프로필",
        location: "서울 강남구"
    )
}

struct MockSearchRepository: SearchRepository {
    func searchBooks(query: String) async -> [BookSummary] {
        guard query.isEmpty == false else { return MockFixture.books }
        return MockFixture.books.filter { book in
            book.title.localizedCaseInsensitiveContains(query) ||
            book.author.localizedCaseInsensitiveContains(query) ||
            book.publisher.localizedCaseInsensitiveContains(query)
        }
    }
}

struct MockBookRepository: BookRepository {
    func fetchBookDetail(id: String) async -> BookDetail? {
        if id == MockFixture.bookDetail.id {
            return MockFixture.bookDetail
        }
        return BookDetail(
            id: id,
            title: "아몬드",
            author: "홍길동",
            publisher: "개발출판사",
            year: "2024",
            summary: MockFixture.bookDetail.summary
        )
    }
}

struct MockLibraryRepository: LibraryRepository {
    func fetchHomeLibraries(distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary] {
        let filteredByDistance: [LibrarySummary]
        switch distance {
        case .oneKm:
            filteredByDistance = Array(MockFixture.libraries.prefix(2))
        case .twoKm:
            filteredByDistance = Array(MockFixture.libraries.prefix(3))
        case .threeKm:
            filteredByDistance = MockFixture.libraries
        }

        if excludeClosed {
            return filteredByDistance.filter { $0.operatingStatus == .open }
        }

        return filteredByDistance
    }

    func fetchNearbyLibraries(query: SearchQuery) async -> [LibrarySummary] {
        let filtered = MockFixture.libraries.filter { library in
            query.text.isEmpty ||
            library.name.localizedCaseInsensitiveContains(query.text) ||
            library.address.localizedCaseInsensitiveContains(query.text)
        }

        if query.excludeUnavailable {
            return filtered.filter { $0.loanStatus != .borrowed }
        }

        return filtered
    }

    func fetchLibraryDetail(id: String) async -> LibraryDetail? {
        MockFixture.libraryDetail
    }
}

struct MockFavoritesRepository: FavoritesRepository {
    func fetchFavoriteBooks() async -> [BookSummary] {
        MockFixture.books.prefix(2).map { $0 }
    }

    func fetchFavoriteLibraries() async -> [LibrarySummary] {
        Array(MockFixture.libraries.prefix(2))
    }
}

struct MockAlertsRepository: AlertsRepository {
    func fetchAlerts() async -> [AlertItem] {
        MockFixture.alerts
    }
}

struct MockProfileRepository: ProfileRepository {
    func fetchProfile() async -> UserProfile {
        MockFixture.profile
    }
}
