//
//  PolarisTests.swift
//  PolarisTests
//
//  Created by 손유나 on 3/27/26.
//

import Foundation
import Testing
@testable import Polaris

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            fatalError("URLProtocolStub.requestHandler must be set before use.")
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeStubbedSession(
    handler: @escaping @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)
) -> URLSession {
    URLProtocolStub.requestHandler = handler
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    return URLSession(configuration: configuration)
}

private struct StubLocationAddressService: LocationAddressService {
    let currentAddress: AddressSuggestion
    let resolvedAddress: AddressSuggestion

    func requestCurrentAddress() async throws -> AddressSuggestion {
        currentAddress
    }

    func resolveAddress(roadAddress: String, detailText: String) async throws -> AddressSuggestion {
        AddressSuggestion(
            id: resolvedAddress.id,
            roadAddress: roadAddress,
            detailText: detailText,
            latitude: resolvedAddress.latitude,
            longitude: resolvedAddress.longitude
        )
    }
}

private struct FixedSearchRepository: SearchRepository {
    let books: [BookSummary]

    func searchBooks(query: String) async -> [BookSummary] {
        books
    }
}

private final class RecordingLibraryRepository: LibraryRepository {
    var nearbyRequestedBookIDs: [String?] = []
    var shouldPauseNearbyFetch = false
    private var nearbyFetchContinuation: CheckedContinuation<Void, Never>?
    private let responsesByBookID: [String: [LibrarySummary]]

    init(responsesByBookID: [String: [LibrarySummary]] = [:]) {
        self.responsesByBookID = responsesByBookID
    }

    func fetchHomeLibraries(origin: AddressSuggestion, distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary] {
        []
    }

    func fetchNearbyLibraries(origin: AddressSuggestion, distance: DistanceOption, query: SearchQuery, selectedBookID: String?) async -> [LibrarySummary] {
        nearbyRequestedBookIDs.append(selectedBookID)
        if shouldPauseNearbyFetch {
            await withCheckedContinuation { continuation in
                nearbyFetchContinuation = continuation
            }
        }
        return responsesByBookID[selectedBookID ?? ""] ?? []
    }

    func fetchLibraryDetail(id: String) async -> LibraryDetail? {
        nil
    }

    func resumeNearbyFetch() {
        nearbyFetchContinuation?.resume()
        nearbyFetchContinuation = nil
    }
}

private func makeTestBook(id: String, title: String) -> BookSummary {
    BookSummary(
        id: id,
        title: title,
        author: "테스트 저자",
        publisher: "테스트 출판사",
        year: "2026",
        coverImageURL: nil,
        isFavorite: false,
        isAlertEnabled: false,
        loanStatus: nil
    )
}

private func makeTestLibrary(id: String, name: String) -> LibrarySummary {
    LibrarySummary(
        id: id,
        name: name,
        address: "테스트 주소",
        phone: "02-0000-0000",
        distanceText: "1.0km",
        operatingStatus: .open,
        loanStatus: .available,
        isFavorite: false,
        isAlertEnabled: false
    )
}

private struct FixedFavoritesRepository: FavoritesRepository {
    let books: [BookSummary]
    let libraries: [LibrarySummary]
    let mutationResult: Bool

    func fetchFavoriteBooks() async throws -> [BookSummary] {
        books
    }

    func fetchFavoriteLibraries() async throws -> [LibrarySummary] {
        libraries
    }

    func setBookFavorite(id: String, isFavorite: Bool) async throws {
        if mutationResult == false {
            throw RepositoryError.unavailable
        }
    }

    func setLibraryFavorite(id: String, isFavorite: Bool) async throws {
        if mutationResult == false {
            throw RepositoryError.unavailable
        }
    }
}

private struct FailingFavoritesRepository: FavoritesRepository {
    func fetchFavoriteBooks() async throws -> [BookSummary] {
        throw RepositoryError.unavailable
    }

    func fetchFavoriteLibraries() async throws -> [LibrarySummary] {
        throw RepositoryError.unavailable
    }

    func setBookFavorite(id: String, isFavorite: Bool) async throws {
        throw RepositoryError.unavailable
    }

    func setLibraryFavorite(id: String, isFavorite: Bool) async throws {
        throw RepositoryError.unavailable
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var requests: [URLRequest] = []

    var firstRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.first
    }

    var paths: [String] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap { $0.url?.path }
    }

    var methods: [String] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap(\.httpMethod)
    }

    func record(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        requests.append(request)
    }
}

@MainActor
struct PolarisTests {
    private static func authSession() -> AuthSession {
        AuthSession(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(600),
            userId: 42
        )
    }

    @Test func homeViewModelAppliesDistanceAndClosedFilter() async throws {
        let viewModel = HomeViewModel(libraryRepository: MockLibraryRepository())

        await viewModel.load()
        #expect(viewModel.state.libraries.count == 2)

        await viewModel.didSelectDistance(.tenKm).value
        #expect(viewModel.state.libraries.count == 4)

        await viewModel.didToggleExcludeClosed(true).value
        #expect(viewModel.state.libraries.count == 3)

        await viewModel.didUpdateLocation(
            AddressSuggestion(
                id: "test-location",
                roadAddress: "서울특별시 강남구 테헤란로 133",
                detailText: "역삼동",
                latitude: 37.4995,
                longitude: 127.0311
            )
        ).value
        #expect(viewModel.state.selectedLocation.roadAddress == "서울특별시 강남구 테헤란로 133")
        #expect(viewModel.state.libraries.first?.title == "강남 도서관")
    }

    @Test func searchViewModelReflectsUnavailableToggle() async throws {
        let viewModel = SearchResultsViewModel(
            searchRepository: MockSearchRepository(),
            libraryRepository: MockLibraryRepository(),
            currentLocation: AddressSuggestion(
                id: "test-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "기본 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            currentDistance: .twoKm
        )

        await viewModel.load()
        #expect(viewModel.state.books.count == 3)
        #expect(viewModel.state.libraries.count == 2)
        #expect(viewModel.state.selectedBookID == nil)

        await viewModel.didSelectBook(id: "book-arond-2").value
        #expect(viewModel.state.selectedBookID == "book-arond-2")
        #expect(viewModel.state.books.first(where: { $0.id == "book-arond-2" })?.isSelected == true)
        #expect(viewModel.state.libraries.count == 1)

        await viewModel.didToggleExcludeUnavailable(true).value
        #expect(viewModel.state.libraries.count == 1)

        await viewModel.didSelectDistance(.tenKm).value
        #expect(viewModel.state.libraries.count == 2)
    }

    @Test func searchViewModelAutoSelectsFirstResultAndLoadsHoldingLibraries() async throws {
        let viewModel = SearchResultsViewModel(
            searchRepository: MockSearchRepository(),
            libraryRepository: MockLibraryRepository(),
            currentLocation: AddressSuggestion(
                id: "test-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "기본 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            currentDistance: .twoKm
        )

        await viewModel.didSubmitQuery("아몬드").value

        #expect(viewModel.state.selectedBookID == "book-arond-1")
        #expect(viewModel.state.books.count == 3)
        #expect(viewModel.state.books.first?.isSelected == true)
        #expect(viewModel.state.libraries.count == 2)
        #expect(viewModel.state.libraries.allSatisfy { $0.title.contains("도서관") })
        #expect(viewModel.state.libraries.allSatisfy { $0.badges.count == 2 })
        #expect(viewModel.state.libraries.contains { library in
            library.badges.contains(where: { $0.title == "대출 가능" })
        })
    }

    @Test func searchViewModelRefetchesLibrariesWhenSelectedBookChanges() async throws {
        let books = [
            makeTestBook(id: "book-1", title: "테스트 책 1"),
            makeTestBook(id: "book-2", title: "테스트 책 2")
        ]
        let libraryRepository = RecordingLibraryRepository(
            responsesByBookID: [
                "book-1": [makeTestLibrary(id: "library-1", name: "첫 번째 도서관")],
                "book-2": [makeTestLibrary(id: "library-2", name: "두 번째 도서관")]
            ]
        )
        let viewModel = SearchResultsViewModel(
            searchRepository: FixedSearchRepository(books: books),
            libraryRepository: libraryRepository,
            currentLocation: AddressSuggestion(
                id: "test-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "기본 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            currentDistance: .twoKm
        )

        await viewModel.didSubmitQuery("테스트").value
        #expect(libraryRepository.nearbyRequestedBookIDs == ["book-1"])
        #expect(viewModel.state.selectedBookID == "book-1")
        #expect(viewModel.state.libraries.first?.title == "첫 번째 도서관")

        await viewModel.didSelectBook(id: "book-2").value
        #expect(libraryRepository.nearbyRequestedBookIDs == ["book-1", "book-2"])
        #expect(viewModel.state.selectedBookID == "book-2")
        #expect(viewModel.state.libraries.first?.title == "두 번째 도서관")
    }

    @Test func searchViewModelTracksLoadingStateWhileNearbyLibrariesAreFetching() async throws {
        let books = [makeTestBook(id: "book-1", title: "테스트 책 1")]
        let libraryRepository = RecordingLibraryRepository(
            responsesByBookID: [
                "book-1": [makeTestLibrary(id: "library-1", name: "첫 번째 도서관")]
            ]
        )
        libraryRepository.shouldPauseNearbyFetch = true
        defer { libraryRepository.resumeNearbyFetch() }
        let viewModel = SearchResultsViewModel(
            searchRepository: FixedSearchRepository(books: books),
            libraryRepository: libraryRepository,
            currentLocation: AddressSuggestion(
                id: "test-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "기본 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            currentDistance: .twoKm
        )

        let task = viewModel.didSubmitQuery("테스트")
        #expect(viewModel.state.isBooksLoading == true)
        #expect(viewModel.state.isLibrariesLoading == true)

        for _ in 0..<20 where viewModel.state.isBooksLoading {
            await Task.yield()
        }
        #expect(viewModel.state.isBooksLoading == false)
        #expect(viewModel.state.isLibrariesLoading == true)

        libraryRepository.resumeNearbyFetch()
        await task.value

        #expect(viewModel.state.isBooksLoading == false)
        #expect(viewModel.state.isLibrariesLoading == false)
        #expect(viewModel.state.libraries.first?.title == "첫 번째 도서관")
    }

    @Test func liveLibraryRepositoryDecodesUnknownAvailabilityPayload() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let responseJSON = """
        {
          "hasNext": true,
          "nextCursor": "2.915:846",
          "items": [
            {
              "libraryId": 832,
              "name": "Suwon Library",
              "address": "Suwon",
              "latitude": 37.2596306,
              "longitude": 127.042358,
              "distanceKm": 1.295,
              "hasBook": null,
              "loanAvailable": null,
              "availabilityStatus": "UNKNOWN",
              "openNow": false
            },
            {
              "libraryId": 847,
              "name": "Daegu Library",
              "address": "Daegu",
              "latitude": 35.8692838,
              "longitude": 128.6060779,
              "distanceKm": 1.296,
              "hasBook": null,
              "loanAvailable": null,
              "availabilityStatus": "UNKNOWN",
              "openNow": false
            }
          ]
        }
        """
        let session = makeStubbedSession { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }
        let repository = LiveLibraryRepository(apiClient: PolarisAPIClient(session: session))

        let libraries = await repository.fetchNearbyLibraries(
            origin: AddressSuggestion(
                id: "suwon-cityhall",
                roadAddress: "경기도 수원시 팔달구 효원로 241",
                detailText: "수원시청",
                latitude: 37.2636,
                longitude: 127.0286
            ),
            distance: .tenKm,
            query: SearchQuery(text: "아몬드", excludeUnavailable: false),
            selectedBookID: "9791198363510"
        )

        #expect(libraries.count == 2)
        #expect(libraries.allSatisfy { $0.loanStatus == nil })
    }

    @Test func liveLibraryRepositoryFiltersUnknownRowsWhenExcludeUnavailableIsEnabled() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let responseJSON = """
        {
          "hasNext": false,
          "nextCursor": null,
          "items": [
            {
              "libraryId": 708,
              "name": "Available Library",
              "address": "Seoul",
              "latitude": 37.5663245,
              "longitude": 126.977752,
              "distanceKm": 0.029,
              "hasBook": true,
              "loanAvailable": true,
              "availabilityStatus": "AVAILABLE",
              "openNow": false
            },
            {
              "libraryId": 847,
              "name": "Unknown Library",
              "address": "Suwon",
              "latitude": 37.2741231,
              "longitude": 127.0348936,
              "distanceKm": 1.296,
              "hasBook": null,
              "loanAvailable": null,
              "availabilityStatus": "UNKNOWN",
              "openNow": false
            }
          ]
        }
        """
        let session = makeStubbedSession { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard query.contains(where: { $0.name == "loanAvailable" && $0.value == "true" }) else {
                throw URLError(.badServerResponse)
            }

            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }
        let repository = LiveLibraryRepository(apiClient: PolarisAPIClient(session: session))

        let libraries = await repository.fetchNearbyLibraries(
            origin: AddressSuggestion(
                id: "seoul-cityhall",
                roadAddress: "서울특별시 중구 세종대로 110",
                detailText: "서울시청",
                latitude: 37.5665,
                longitude: 126.9780
            ),
            distance: .tenKm,
            query: SearchQuery(text: "아몬드", excludeUnavailable: true),
            selectedBookID: "9791198363510"
        )

        #expect(libraries.count == 1)
        #expect(libraries.first?.name == "Available Library")
        #expect(libraries.first?.loanStatus == .available)
    }

    @Test func liveLibraryRepositoryUsesFiveKmLimitTwentyForBookAvailabilityQueries() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let responseJSON = """
        {
          "hasNext": false,
          "nextCursor": null,
          "items": []
        }
        """
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }

            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }
        let repository = LiveLibraryRepository(apiClient: PolarisAPIClient(session: session))

        _ = await repository.fetchNearbyLibraries(
            origin: AddressSuggestion(
                id: "yongin-seocheon",
                roadAddress: "경기도 용인시 기흥구 서천동로21번길 21",
                detailText: "서천마을 중앙상가",
                latitude: 37.2410,
                longitude: 127.0724
            ),
            distance: .fiveKm,
            query: SearchQuery(text: "아몬드", excludeUnavailable: false),
            selectedBookID: "9791198363510"
        )

        let capturedURL = requestRecorder.firstRequest?.url
        #expect(capturedURL != nil)
        guard let capturedURL,
              let components = URLComponents(url: capturedURL, resolvingAgainstBaseURL: false) else { return }

        let queryItems = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { item in
            (item.name, item.value ?? "")
        })

        #expect(components.path.hasSuffix("/book-availability"))
        #expect(queryItems["isbn"] == "9791198363510")
        #expect(queryItems["latitude"] == "37.241")
        #expect(queryItems["longitude"] == "127.0724")
        #expect(queryItems["radiusKm"] == "5")
        #expect(queryItems["limit"] == "20")
        #expect(queryItems["loanAvailable"] == nil)
    }

    @Test func liveAPISmokeTestsSuwonAndDaeguCoordinates() async throws {
        guard ProcessInfo.processInfo.environment["POLARIS_RUN_LIVE_API_SMOKE_TESTS"] == "1" else { return }

        let apiClient = PolarisAPIClient()
        let searchRepository = LiveSearchRepository(apiClient: apiClient)
        let libraryRepository = LiveLibraryRepository(apiClient: apiClient)

        let books = await searchRepository.searchBooks(query: "아몬드")
        let isbn = books.first?.id ?? ""
        #expect(isbn.isEmpty == false)

        let coordinates = [
            AddressSuggestion(
                id: "suwon-cityhall",
                roadAddress: "경기도 수원시 팔달구 효원로 241",
                detailText: "수원시청",
                latitude: 37.2636,
                longitude: 127.0286
            ),
            AddressSuggestion(
                id: "daegu-cityhall",
                roadAddress: "대구광역시 중구 공평로 88",
                detailText: "대구시청",
                latitude: 35.8714,
                longitude: 128.6014
            )
        ]

        for coordinate in coordinates {
            let nearbyLibraries = await libraryRepository.fetchHomeLibraries(
                origin: coordinate,
                distance: .fiveKm,
                excludeClosed: false
            )
            #expect(nearbyLibraries.isEmpty == false)

            let holdingLibraries = await libraryRepository.fetchNearbyLibraries(
                origin: coordinate,
                distance: .fiveKm,
                query: SearchQuery(text: "아몬드", excludeUnavailable: false),
                selectedBookID: isbn
            )
            #expect(holdingLibraries.isEmpty == false)
        }
    }

    @Test func likeViewModelSwitchesTabsWithoutLosingData() async throws {
        let viewModel = LikeViewModel(favoritesRepository: MockFavoritesRepository())

        await viewModel.load()
        #expect(viewModel.state.selectedTab == .books)
        #expect(viewModel.state.books.count == 2)
        #expect(viewModel.state.libraries.count == 2)

        viewModel.didSelectTab(index: FavoriteTab.libraries.rawValue)
        #expect(viewModel.state.selectedTab == .libraries)
        #expect(viewModel.state.libraries.first?.title == "강남 도서관")
    }

    @Test func likeViewModelRoutesBookTapToSearchAndDetailButtonToBookDetail() async throws {
        let viewModel = LikeViewModel(favoritesRepository: MockFavoritesRepository())
        var routedRoutes: [AppRoute] = []
        viewModel.onRoute = { routedRoutes.append($0) }

        await viewModel.load()
        guard let firstBook = viewModel.state.books.first else {
            Issue.record("Expected mock favorite books.")
            return
        }

        viewModel.didSelectBook(id: firstBook.id)
        viewModel.didTapBookDetail(id: firstBook.id)

        #expect(routedRoutes == [
            .bookSearch(query: firstBook.title),
            .bookDetail(id: firstBook.id)
        ])
    }

    @Test func likeViewModelRollsBackWhenBookFavoriteMutationFails() async throws {
        let book = BookSummary(
            id: "9791198363510",
            title: "아몬드",
            author: "손원평",
            publisher: "",
            year: "",
            coverImageURL: nil,
            isFavorite: true,
            isAlertEnabled: false,
            loanStatus: nil
        )
        let viewModel = LikeViewModel(
            favoritesRepository: FixedFavoritesRepository(
                books: [book],
                libraries: [],
                mutationResult: false
            )
        )

        await viewModel.load()
        await viewModel.didToggleBookFavorite(id: "9791198363510")

        #expect(viewModel.state.books.count == 1)
        #expect(viewModel.state.books.first?.isFavorite == true)
        #expect(viewModel.state.errorMessage == "도서 찜 상태를 변경하지 못했습니다.")
    }

    @Test func likeViewModelShowsErrorWhenFavoriteListFetchFails() async throws {
        let viewModel = LikeViewModel(favoritesRepository: FailingFavoritesRepository())

        await viewModel.load()

        #expect(viewModel.state.books.isEmpty)
        #expect(viewModel.state.libraries.isEmpty)
        #expect(viewModel.state.errorMessage == "찜 목록을 불러오지 못했습니다.")
    }

    @Test func liveProfileRepositoryDecodesCurrentUserWithBearerToken() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let responseJSON = """
        {
          "id": 42,
          "provider": "KAKAO",
          "role": "USER",
          "nickname": "북극성",
          "email": "user@example.com",
          "profileImageUrl": "https://example.com/profile.png"
        }
        """
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data(responseJSON.utf8))
        }
        let authRepository = MockAuthRepository(session: Self.authSession())
        let repository = LiveProfileRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: authRepository
        )

        let profile = try await repository.fetchProfile()
        let capturedRequest = requestRecorder.firstRequest

        #expect(capturedRequest?.url?.path.hasSuffix("/users/me") == true)
        #expect(capturedRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
        #expect(profile.id == "42")
        #expect(profile.nickname == "북극성")
        #expect(profile.profileImageURL?.absoluteString == "https://example.com/profile.png")
    }

    @Test func liveProfileRepositoryRetriesAfterUnauthorizedResponse() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let responseJSON = """
        {
          "id": 42,
          "provider": "KAKAO",
          "role": "USER",
          "nickname": "재시도",
          "email": "retry@example.com",
          "profileImageUrl": null
        }
        """
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let isFirstRequest = requestRecorder.paths.count == 1
            let response = HTTPURLResponse(
                url: url,
                statusCode: isFirstRequest ? 401 : 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, isFirstRequest ? Data() : Data(responseJSON.utf8))
        }
        let repository = LiveProfileRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        let profile = try await repository.fetchProfile()

        #expect(requestRecorder.paths.filter { $0.hasSuffix("/users/me") }.count == 2)
        #expect(profile.nickname == "재시도")
    }

    @Test func liveFavoritesRepositoryUsesBookmarkEndpointsAndDecodesItems() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let session = makeStubbedSession { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            requestRecorder.record(request)

            let response = HTTPURLResponse(
                url: url,
                statusCode: url.path.contains("/bookmark") ? 204 : 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if url.path.hasSuffix("/users/me/bookmarked-books") {
                return (response, Data(#"{"items":[{"isbn":9791198363510,"title":"아몬드","author":"손원평","coverImageUrl":"https://example.com/book.jpg"}]}"#.utf8))
            }
            if url.path.hasSuffix("/users/me/bookmarked-libraries") {
                return (response, Data(#"{"items":[{"libraryId":1,"name":"구미시립양포도서관","address":"경상북도 구미시 옥계북로 51"}]}"#.utf8))
            }
            return (response, Data())
        }
        let repository = LiveFavoritesRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        let books = try await repository.fetchFavoriteBooks()
        let libraries = try await repository.fetchFavoriteLibraries()
        try await repository.setBookFavorite(id: "9791198363510", isFavorite: false)
        try await repository.setLibraryFavorite(id: "1", isFavorite: true)
        let requestedPaths = requestRecorder.paths
        let requestedMethods = requestRecorder.methods

        #expect(requestedPaths.contains { $0.hasSuffix("/users/me/bookmarked-books") })
        #expect(requestedPaths.contains { $0.hasSuffix("/users/me/bookmarked-libraries") })
        #expect(requestedPaths.contains { $0.hasSuffix("/books/9791198363510/bookmark") })
        #expect(requestedPaths.contains { $0.hasSuffix("/libraries/1/bookmark") })
        #expect(requestedMethods.contains("DELETE"))
        #expect(requestedMethods.contains("POST"))
        #expect(books.first?.id == "9791198363510")
        #expect(books.first?.isFavorite == true)
        #expect(libraries.first?.id == "1")
        #expect(libraries.first?.distanceText == "경상북도 구미시 옥계북로 51")
    }

    @Test func alarmViewModelGroupsItemsBySection() async throws {
        let viewModel = AlarmViewModel(alertsRepository: MockAlertsRepository())

        await viewModel.load()
        #expect(viewModel.state.sections[.available]?.count == 1)
        #expect(viewModel.state.sections[.waiting]?.count == 1)
        #expect(viewModel.state.sections[.available]?.first?.libraryName == "강남 도서관")
    }

    @Test func locationPickerViewModelAcceptsPostcodeSelection() async throws {
        let locationService = StubLocationAddressService(
            currentAddress: AddressSuggestion(
                id: "current-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "현재 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            resolvedAddress: AddressSuggestion(
                id: "resolved-address",
                roadAddress: "경기도 용인시 기흥구 서천동로21번길 21",
                detailText: "서천마을 중앙상가",
                latitude: 37.2410,
                longitude: 127.0724
            )
        )
        let viewModel = LocationPickerViewModel(
            currentLocation: locationService.currentAddress,
            locationAddressService: locationService
        )

        var selectedSuggestion: AddressSuggestion?
        viewModel.onAddressSelected = { suggestion in
            selectedSuggestion = suggestion
        }

        viewModel.didSelectPostcode(
            PostcodeSelection(
                roadAddress: "경기도 용인시 기흥구 서천동로21번길 21",
                jibunAddress: "경기도 용인시 기흥구 서천동 123-4",
                buildingName: "서천마을 중앙상가",
                legalDongName: "서천동",
                zoneCode: "17112"
            )
        )
        try await Task.sleep(for: .milliseconds(20))

        viewModel.didTapConfirm()

        #expect(viewModel.state.selectedAddress?.roadAddress == "경기도 용인시 기흥구 서천동로21번길 21")
        #expect(selectedSuggestion?.detailText == "서천마을 중앙상가 · 서천동 · 경기도 용인시 기흥구 서천동 123-4")
    }
}
