//
//  PolarisTests.swift
//  PolarisTests
//
//  Created by 손유나 on 3/27/26.
//

import Foundation
import Testing
import UIKit
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
    var isNearbyFetchPaused: Bool {
        nearbyFetchContinuation != nil
    }

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
        loanStatus: nil,
        voteSummary: .empty
    )
}

private func makeTestBookDetail(id: String, voteSummary: BookVoteSummary = .empty) -> BookDetail {
    BookDetail(
        id: id,
        title: "테스트 도서",
        author: "테스트 저자",
        publisher: "테스트 출판사",
        year: "2026",
        coverImageURL: nil,
        summary: "테스트 설명",
        isFavorite: false,
        voteSummary: voteSummary
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

private func findSubview<View: UIView>(
    in rootView: UIView,
    ofType type: View.Type,
    where predicate: (View) -> Bool
) -> View? {
    if let view = rootView as? View, predicate(view) {
        return view
    }

    for subview in rootView.subviews {
        if let match = findSubview(in: subview, ofType: type, where: predicate) {
            return match
        }
    }

    return nil
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

private final class RecordingFavoritesRepository: FavoritesRepository {
    private(set) var libraryMutations: [(id: String, isFavorite: Bool)] = []

    func fetchFavoriteBooks() async throws -> [BookSummary] {
        []
    }

    func fetchFavoriteLibraries() async throws -> [LibrarySummary] {
        []
    }

    func setBookFavorite(id: String, isFavorite: Bool) async throws {
    }

    func setLibraryFavorite(id: String, isFavorite: Bool) async throws {
        libraryMutations.append((id, isFavorite))
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

private struct FixedBookRepository: BookRepository {
    let detail: BookDetail?

    func fetchBookDetail(id: String) async -> BookDetail? {
        detail
    }
}

private final class RecordingBookVoteRepository: BookVoteRepository {
    private(set) var votes: [(id: String, voteType: BookVoteType)] = []
    var shouldFail = false

    func voteBook(id: String, voteType: BookVoteType) async throws {
        votes.append((id, voteType))
        if shouldFail {
            throw RepositoryError.unavailable
        }
    }
}

private final class RecordingAlertsRepository: AlertsRepository {
    private let alerts: [AlertItem]
    private let subscriptions: [AlertItem]
    private(set) var mutations: [(bookID: String, libraryID: String, isEnabled: Bool)] = []
    private(set) var deletedAlertIDs: [String] = []
    var shouldFailMutation = false
    var shouldFailDelete = false

    init(alerts: [AlertItem] = [], subscriptions: [AlertItem] = []) {
        self.alerts = alerts
        self.subscriptions = subscriptions
    }

    func fetchAlerts() async throws -> [AlertItem] {
        alerts
    }

    func fetchAlertSubscriptions() async throws -> [AlertItem] {
        subscriptions
    }

    func deleteAlert(id: String) async throws {
        deletedAlertIDs.append(id)
        if shouldFailDelete {
            throw RepositoryError.unavailable
        }
    }

    func setAlertSubscription(bookID: String, libraryID: String, isEnabled: Bool) async throws {
        mutations.append((bookID, libraryID, isEnabled))
        if shouldFailMutation {
            throw RepositoryError.unavailable
        }
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private struct RecordedRequest {
        let request: URLRequest
        let body: Data?
    }

    private let lock = NSLock()
    private var requests: [RecordedRequest] = []

    var firstRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return requests.first?.request
    }

    var recordedRequests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return requests.map(\.request)
    }

    var paths: [String] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap { $0.request.url?.path }
    }

    var methods: [String] {
        lock.lock()
        defer { lock.unlock() }
        return requests.compactMap { $0.request.httpMethod }
    }

    func record(_ request: URLRequest) {
        let body = Self.bodyData(from: request)
        lock.lock()
        defer { lock.unlock() }
        requests.append(RecordedRequest(request: request, body: body))
    }

    func bodyString(where predicate: (URLRequest) -> Bool) -> String? {
        lock.lock()
        defer { lock.unlock() }
        guard let body = requests.first(where: { predicate($0.request) })?.body else { return nil }
        return String(data: body, encoding: .utf8)
    }

    private static func bodyData(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }
        guard let stream = request.httpBodyStream else { return nil }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let readCount = stream.read(&buffer, maxLength: buffer.count)
            if readCount > 0 {
                data.append(buffer, count: readCount)
            } else {
                break
            }
        }
        return data.isEmpty ? nil : data
    }
}

@Suite(.serialized)
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

        await viewModel.didSelectBook(id: "book-arond-1").value
        #expect(viewModel.state.selectedBookID == "book-arond-1")
        #expect(viewModel.state.books.first(where: { $0.id == "book-arond-1" })?.isSelected == true)
        #expect(viewModel.state.libraries.count == 2)

        await viewModel.didToggleExcludeUnavailable(true).value
        #expect(viewModel.state.libraries.count == 1)
        #expect(viewModel.state.libraries.allSatisfy { library in
            library.badges.contains(where: { $0.title == "대출 가능" })
        })

        await viewModel.didSelectDistance(.tenKm).value
        #expect(viewModel.state.libraries.count == 1)
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

    @Test func searchViewModelTogglesAlertSubscriptionForSelectedBookAndLibrary() async throws {
        let books = [makeTestBook(id: "book-1", title: "테스트 책 1")]
        let libraryRepository = RecordingLibraryRepository(
            responsesByBookID: [
                "book-1": [makeTestLibrary(id: "1", name: "첫 번째 도서관")]
            ]
        )
        let alertsRepository = RecordingAlertsRepository()
        let viewModel = SearchResultsViewModel(
            searchRepository: FixedSearchRepository(books: books),
            libraryRepository: libraryRepository,
            alertsRepository: alertsRepository,
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
        #expect(viewModel.state.libraries.first?.showsBell == true)
        #expect(viewModel.state.libraries.first?.isBellActive == false)

        await viewModel.didToggleLibraryAlert(id: "1")

        #expect(alertsRepository.mutations.count == 1)
        #expect(alertsRepository.mutations.first?.bookID == "book-1")
        #expect(alertsRepository.mutations.first?.libraryID == "1")
        #expect(alertsRepository.mutations.first?.isEnabled == true)
        #expect(viewModel.state.libraries.first?.isBellActive == true)
    }

    @Test func searchViewModelTogglesLibraryFavorite() async throws {
        let books = [makeTestBook(id: "book-1", title: "테스트 책 1")]
        let libraryRepository = RecordingLibraryRepository(
            responsesByBookID: [
                "book-1": [makeTestLibrary(id: "1", name: "첫 번째 도서관")]
            ]
        )
        let favoritesRepository = RecordingFavoritesRepository()
        let viewModel = SearchResultsViewModel(
            searchRepository: FixedSearchRepository(books: books),
            libraryRepository: libraryRepository,
            favoritesRepository: favoritesRepository,
            currentLocation: AddressSuggestion.defaultLocation,
            currentDistance: .twoKm
        )

        await viewModel.didSubmitQuery("테스트").value
        #expect(viewModel.state.libraries.first?.isFavorite == false)

        await viewModel.didToggleLibraryFavorite(id: "1")

        #expect(favoritesRepository.libraryMutations.count == 1)
        #expect(favoritesRepository.libraryMutations.first?.id == "1")
        #expect(favoritesRepository.libraryMutations.first?.isFavorite == true)
        #expect(viewModel.state.libraries.first?.isFavorite == true)
    }

    @MainActor
    @Test func libraryCardFavoriteButtonCanReceiveTouches() async throws {
        let cell = LibraryCardCell(frame: CGRect(x: 0, y: 0, width: 320, height: 120))
        cell.configure(viewData: LibraryCardItemViewData(
            id: "1",
            title: "첫 번째 도서관",
            distanceText: "1.0km",
            badges: [makeOperatingBadge(.open)],
            showsBell: false,
            showsFavorite: true,
            isBellActive: false,
            isFavorite: false
        ))

        let favoriteButton = try #require(findSubview(
            in: cell,
            ofType: UIButton.self,
            where: { $0.accessibilityIdentifier == "libraryCardCell.favoriteButton" }
        ))
        var didTapFavorite = false
        cell.onHeartTap = {
            didTapFavorite = true
        }

        #expect(favoriteButton.isHidden == false)
        #expect(favoriteButton.superview?.isUserInteractionEnabled == true)
        favoriteButton.sendActions(for: .touchUpInside)
        #expect(didTapFavorite == true)
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

        for _ in 0..<200 where libraryRepository.isNearbyFetchPaused == false {
            await Task.yield()
        }
        guard libraryRepository.isNearbyFetchPaused else {
            Issue.record("Expected nearby library fetch to be paused before resuming it.")
            return
        }
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
            loanStatus: nil,
            voteSummary: .empty
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

    @Test func bookDetailViewModelRecommendsOptimisticallyOnce() async throws {
        let voteRepository = RecordingBookVoteRepository()
        let detail = makeTestBookDetail(
            id: "9791198363510",
            voteSummary: BookVoteSummary(recommendCount: 2, notRecommendCount: 1, myVote: nil)
        )
        let viewModel = BookDetailViewModel(
            bookID: detail.id,
            bookRepository: FixedBookRepository(detail: detail),
            favoritesRepository: FixedFavoritesRepository(books: [], libraries: [], mutationResult: true),
            bookVoteRepository: voteRepository
        )

        await viewModel.load()
        await viewModel.didTapVote(.recommend)
        await viewModel.didTapVote(.recommend)

        #expect(voteRepository.votes.map(\.voteType) == [.recommend])
        #expect(viewModel.state.voteSummary.recommendCount == 3)
        #expect(viewModel.state.voteSummary.notRecommendCount == 1)
        #expect(viewModel.state.voteSummary.myVote == .recommend)
        #expect(viewModel.state.isMutatingVote == false)
    }

    @Test func bookDetailViewModelRestoresVoteWhenMutationFails() async throws {
        let voteRepository = RecordingBookVoteRepository()
        voteRepository.shouldFail = true
        let originalVoteSummary = BookVoteSummary(recommendCount: 4, notRecommendCount: 2, myVote: nil)
        let viewModel = BookDetailViewModel(
            bookID: "9791198363510",
            bookRepository: FixedBookRepository(
                detail: makeTestBookDetail(id: "9791198363510", voteSummary: originalVoteSummary)
            ),
            favoritesRepository: FixedFavoritesRepository(books: [], libraries: [], mutationResult: true),
            bookVoteRepository: voteRepository
        )

        await viewModel.load()
        await viewModel.didTapVote(.recommend)

        #expect(viewModel.state.voteSummary == originalVoteSummary)
        #expect(viewModel.state.voteErrorMessage == "도서 투표를 반영하지 못했습니다.")
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

    @Test func liveFavoritesRepositoryTreatsSatisfiedBookmarkMutationsAsSuccess() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let session = makeStubbedSession { request in
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            requestRecorder.record(request)

            let statusCode: Int
            switch request.httpMethod {
            case "POST":
                statusCode = 409
            case "DELETE":
                statusCode = 404
            default:
                statusCode = 200
            }

            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let repository = LiveFavoritesRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        try await repository.setBookFavorite(id: "9791198363510", isFavorite: true)
        try await repository.setBookFavorite(id: "9791198363510", isFavorite: false)

        #expect(requestRecorder.paths.filter { $0.hasSuffix("/books/9791198363510/bookmark") }.count == 2)
        #expect(requestRecorder.methods == ["POST", "DELETE"])
    }

    @Test func liveBookVoteRepositoryUsesVoteEndpointAndBody() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 204,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let repository = LiveBookVoteRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        try await repository.voteBook(id: "9791198363510", voteType: .recommend)

        let body = requestRecorder.bodyString { $0.httpMethod == "PUT" }
        #expect(requestRecorder.paths.first?.hasSuffix("/books/9791198363510/vote") == true)
        #expect(requestRecorder.methods.first == "PUT")
        #expect(requestRecorder.firstRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer access-token")
        #expect(requestRecorder.firstRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json;charset=UTF-8")
        #expect(body?.contains(#""voteType":"RECOMMEND""#) == true)
    }

    @Test func liveAlertsRepositoryUsesNotificationListAndDeleteEndpoints() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let responseJSON = """
        {
          "hasNext": false,
          "nextCursor": null,
          "items": [
            {
              "notificationId": 123,
              "notificationType": "BOOK_AVAILABLE",
              "isbn": "9791198363510",
              "bookTitle": "아몬드",
              "libraryId": 456,
              "libraryName": "구미시립중앙도서관",
              "title": "대출 가능 알림",
              "message": "알림 받기 한 도서가 구미시립중앙도서관에서 대출 가능합니다.",
              "notificationDate": "2026-05-07",
              "createdAt": "2026-05-07T09:00:01"
            }
          ]
        }
        """
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let statusCode = request.httpMethod == "GET" ? 200 : 204
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, request.httpMethod == "GET" ? Data(responseJSON.utf8) : Data())
        }
        let repository = LiveAlertsRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        let alerts = try await repository.fetchAlerts()
        try await repository.deleteAlert(id: "123")

        let requests = requestRecorder.recordedRequests
        let getURL = requests.first(where: { $0.httpMethod == "GET" })?.url
        let getQueryItems = getURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        let getQuery = Dictionary(uniqueKeysWithValues: getQueryItems.map { ($0.name, $0.value ?? "") })

        #expect(alerts.first?.id == "123")
        #expect(alerts.first?.book.id == "9791198363510")
        #expect(alerts.first?.book.title == "아몬드")
        #expect(alerts.first?.book.coverImageURL?.absoluteString.contains("9791198363510") == true)
        #expect(alerts.first?.libraryID == "456")
        #expect(alerts.first?.libraryName == "구미시립중앙도서관")
        #expect(alerts.first?.section == .available)
        #expect(alerts.first?.message?.contains("대출 가능합니다") == true)
        #expect(requestRecorder.paths.contains { $0.hasSuffix("/notifications") })
        #expect(requestRecorder.paths.contains { $0.hasSuffix("/notifications/123") })
        #expect(requestRecorder.methods == ["GET", "DELETE"])
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer access-token" })
        #expect(getQuery["limit"] == "20")
    }

    @Test func liveAlertsRepositoryUsesNotificationSubscriptionEndpoints() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let responseJSON = """
        [
          {
            "subscriptionId": 123,
            "isbn": "9791198363510",
            "title": "아몬드",
            "author": "손원평",
            "coverImageUrl": "https://example.com/book.jpg",
            "libraryId": 456,
            "libraryName": "구미시립중앙도서관",
            "lastStableAvailability": "AVAILABLE",
            "lastCheckOutcome": "OK",
            "lastCheckedAt": "2026-05-05T00:00:00Z",
            "lastNotifiedAt": null
          }
        ]
        """
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let statusCode = request.httpMethod == "GET" ? 200 : 204
            let response = HTTPURLResponse(
                url: url,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, request.httpMethod == "GET" ? Data(responseJSON.utf8) : Data())
        }
        let repository = LiveAlertsRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        let alerts = try await repository.fetchAlertSubscriptions()
        try await repository.setAlertSubscription(bookID: "9791198363510", libraryID: "456", isEnabled: true)
        try await repository.setAlertSubscription(bookID: "9791198363510", libraryID: "456", isEnabled: false)

        let requests = requestRecorder.recordedRequests
        let postBody = requestRecorder.bodyString { $0.httpMethod == "POST" }
        let deleteURL = requests.first(where: { $0.httpMethod == "DELETE" })?.url
        let deleteQueryItems = deleteURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        let deleteQuery = Dictionary(uniqueKeysWithValues: deleteQueryItems.map { ($0.name, $0.value ?? "") })

        #expect(alerts.first?.id == "123")
        #expect(alerts.first?.book.id == "9791198363510")
        #expect(alerts.first?.libraryID == "456")
        #expect(alerts.first?.section == .available)
        #expect(requestRecorder.paths.contains { $0.hasSuffix("/notifications/subscriptions/me") })
        #expect(requestRecorder.paths.filter { $0.hasSuffix("/notifications/subscriptions") }.count == 2)
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer access-token" })
        #expect(postBody?.contains(#""isbn":"9791198363510""#) == true)
        #expect(postBody?.contains(#""libraryId":456"#) == true)
        #expect(deleteQuery["isbn"] == "9791198363510")
        #expect(deleteQuery["libraryId"] == "456")
    }

    @Test func livePushNotificationRepositoryRegistersAndDeletesIOSToken() async throws {
        defer { URLProtocolStub.requestHandler = nil }

        let requestRecorder = RequestRecorder()
        let session = makeStubbedSession { request in
            requestRecorder.record(request)
            guard let url = request.url else {
                throw URLError(.badURL)
            }
            let response = HTTPURLResponse(
                url: url,
                statusCode: 204,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data())
        }
        let repository = LivePushNotificationRepository(
            apiClient: PolarisAPIClient(session: session),
            authRepository: MockAuthRepository(session: Self.authSession())
        )

        try await repository.registerDeviceToken("fcm-token")
        try await repository.deleteDeviceToken("fcm-token")

        let requests = requestRecorder.recordedRequests
        let postBody = requestRecorder.bodyString { $0.httpMethod == "POST" }
        let deleteURL = requests.first(where: { $0.httpMethod == "DELETE" })?.url
        let deleteQueryItems = deleteURL.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        let deleteQuery = Dictionary(uniqueKeysWithValues: deleteQueryItems.map { ($0.name, $0.value ?? "") })

        #expect(requestRecorder.paths.allSatisfy { $0.hasSuffix("/notifications/tokens") })
        #expect(requestRecorder.methods == ["POST", "DELETE"])
        #expect(requests.allSatisfy { $0.value(forHTTPHeaderField: "Authorization") == "Bearer access-token" })
        #expect(postBody?.contains(#""platform":"IOS""#) == true)
        #expect(postBody?.contains(#""deviceToken":"fcm-token""#) == true)
        #expect(deleteQuery["platform"] == "IOS")
        #expect(deleteQuery["deviceToken"] == "fcm-token")
    }

    @Test func alarmViewModelGroupsItemsBySection() async throws {
        let viewModel = AlarmViewModel(alertsRepository: MockAlertsRepository())

        await viewModel.load()
        #expect(viewModel.state.sections[.available]?.count == 2)
        #expect(viewModel.state.sections[.waiting]?.count == 2)
        #expect(viewModel.state.sections[.available]?.first?.libraryName == "강남 도서관")
        #expect(viewModel.state.sections[.available]?.first?.metadataText == "강남 도서관에서 대출가능 상태로 바뀌었습니다.")
        #expect(viewModel.state.sections[.available]?.first?.coverImageURL?.absoluteString.contains("9788936434267") == true)
        #expect(viewModel.state.sections[.available]?.first?.action == .delete)
        #expect(viewModel.state.sections[.waiting]?.first?.coverImageURL?.absoluteString.contains("9788936434120") == true)
        #expect(viewModel.state.sections[.waiting]?.first?.action == .unsubscribe)
    }

    @Test func alarmViewModelDeletesAlertOptimistically() async throws {
        let alert = AlertItem(
            id: "123",
            section: .available,
            book: makeTestBook(id: "9791198363510", title: "아몬드"),
            libraryID: "456",
            libraryName: "구미시립중앙도서관"
        )
        let alertsRepository = RecordingAlertsRepository(alerts: [alert])
        let viewModel = AlarmViewModel(alertsRepository: alertsRepository)

        await viewModel.load()
        await viewModel.didDeleteAlert(id: "123")

        #expect(alertsRepository.deletedAlertIDs == ["123"])
        #expect(viewModel.state.sections.isEmpty)
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
