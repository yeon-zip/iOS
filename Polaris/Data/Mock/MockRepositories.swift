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

    static let gumiLibraries: [LibrarySummary] = [
        LibrarySummary(id: "library-gumi-central", name: "구미시립중앙도서관", address: "경상북도 구미시 대학로 61", phone: "054-480-4660", distanceText: "0.3km", operatingStatus: .open, loanStatus: .available, isFavorite: true, isAlertEnabled: true),
        LibrarySummary(id: "library-geumo", name: "금오도서관", address: "경상북도 구미시 형곡로 140", phone: "054-450-7000", distanceText: "0.8km", operatingStatus: .open, loanStatus: .borrowed, isFavorite: false, isAlertEnabled: false),
        LibrarySummary(id: "library-hyeonggok", name: "형곡도서관", address: "경상북도 구미시 형곡동 235", phone: "054-461-2300", distanceText: "1.6km", operatingStatus: .closed, loanStatus: .available, isFavorite: false, isAlertEnabled: false),
        LibrarySummary(id: "library-indong", name: "인동도서관", address: "경상북도 구미시 인동가산로 392", phone: "054-476-3100", distanceText: "2.7km", operatingStatus: .open, loanStatus: nil, isFavorite: false, isAlertEnabled: false)
    ]

    static let bookHoldings: [String: Set<String>] = [
        "book-arond-1": ["library-gangnam", "library-daechi"],
        "book-arond-2": ["library-gangnam", "library-yeoksam"],
        "book-arond-3": ["library-daechi", "library-suseo"]
    ]

    static let alerts: [AlertItem] = [
        AlertItem(
            id: "alert-1",
            section: .available,
            book: BookSummary(id: "alert-book-1", title: "아몬드", author: "김철수", publisher: "인사이트", year: "2024", isFavorite: true, isAlertEnabled: true, loanStatus: .available),
            libraryName: "강남 도서관"
        ),
        AlertItem(
            id: "alert-2",
            section: .waiting,
            book: BookSummary(id: "alert-book-2", title: "아몬드", author: "김철수", publisher: "인사이트", year: "2024", isFavorite: false, isAlertEnabled: true, loanStatus: .notificationReady),
            libraryName: "역삼도서관"
        )
    ]

    static let libraryDetails: [String: LibraryDetail] = [
        "library-yeoksam": LibraryDetail(
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
        ),
        "library-gumi-central": LibraryDetail(
            id: "library-gumi-central",
            name: "구미시립중앙도서관",
            address: "경상북도 구미시 대학로 61",
            phone: "054-480-4660",
            hours: [
                OperatingHour(day: "평일", hoursText: "09:00 - 21:00", isClosed: false),
                OperatingHour(day: "토요일", hoursText: "09:00 - 18:00", isClosed: false),
                OperatingHour(day: "일요일", hoursText: "휴관", isClosed: true)
            ],
            regularHolidays: [
                HolidayEntry(title: "매주 일요일"),
                HolidayEntry(title: "국경일")
            ],
            upcomingHolidays: [
                HolidayEntry(title: "5월 5일 어린이날"),
                HolidayEntry(title: "6월 6일 현충일")
            ],
            mapDescription: "구미역과 금오산 사이 중심 생활권"
        )
    ]

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
    func fetchHomeLibraries(origin: AddressSuggestion, distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary] {
        let sourceLibraries = origin.roadAddress.contains("구미") ? MockFixture.gumiLibraries : MockFixture.libraries
        let filteredByDistance: [LibrarySummary]
        switch distance {
        case .oneKm:
            filteredByDistance = Array(sourceLibraries.prefix(2))
        case .twoKm:
            filteredByDistance = Array(sourceLibraries.prefix(3))
        case .threeKm:
            filteredByDistance = sourceLibraries
        }

        if excludeClosed {
            return filteredByDistance.filter { $0.operatingStatus == .open }
        }

        return filteredByDistance
    }

    func fetchNearbyLibraries(query: SearchQuery, selectedBookID: String?) async -> [LibrarySummary] {
        let filtered: [LibrarySummary]
        if let selectedBookID, let libraryIDs = MockFixture.bookHoldings[selectedBookID] {
            filtered = MockFixture.libraries.filter { libraryIDs.contains($0.id) }
        } else {
            filtered = MockFixture.libraries
        }

        if query.excludeUnavailable {
            return filtered.filter { $0.loanStatus != .borrowed }
        }

        return filtered
    }

    func fetchLibraryDetail(id: String) async -> LibraryDetail? {
        MockFixture.libraryDetails[id] ?? MockFixture.libraryDetails["library-yeoksam"]
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
