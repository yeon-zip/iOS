//
//  MockRepositories.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

final class PolarisAPIClient {
    private let session: URLSession

    init(session: URLSession = .polarisDefault) {
        self.session = session
    }

    func get<Response: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async -> Response? {
        guard let url = PolarisAPI.makeURL(path: path, queryItems: queryItems) else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = PolarisAPI.requestTimeout

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  200..<300 ~= httpResponse.statusCode else {
                debugLog("HTTP request failed: \(url.absoluteString)")
                if let httpResponse = response as? HTTPURLResponse {
                    debugLog("Status code: \(httpResponse.statusCode)")
                }
                return nil
            }
            do {
                return try JSONDecoder.polaris.decode(Response.self, from: data)
            } catch {
                debugLog("Decoding failed for: \(url.absoluteString)")
                debugLog("\(error)")
                return nil
            }
        } catch {
            debugLog("Network request failed: \(url.absoluteString)")
            debugLog("\(error)")
            return nil
        }
    }
}

private func debugLog(_ message: String) {
#if DEBUG
    print("[PolarisAPI] \(message)")
#endif
}

private enum PolarisAPI {
    static let baseURL = URL(string: "https://api.k-polaris.life/api/v1")!
    static let requestTimeout: TimeInterval = 60

    static func makeURL(path: String, queryItems: [URLQueryItem]) -> URL? {
        let sanitizedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(
            url: baseURL.appendingPathComponent(sanitizedPath),
            resolvingAgainstBaseURL: false
        )
        let filteredQueryItems = queryItems.filter { $0.value != nil }
        components?.queryItems = filteredQueryItems.isEmpty ? nil : filteredQueryItems
        return components?.url
    }
}

private extension URLSession {
    static let polarisDefault: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = PolarisAPI.requestTimeout
        configuration.timeoutIntervalForResource = PolarisAPI.requestTimeout + 5
        return URLSession(configuration: configuration)
    }()
}

private extension JSONDecoder {
    static let polaris: JSONDecoder = {
        let decoder = JSONDecoder()
        return decoder
    }()
}

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int64.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
        }
        throw DecodingError.typeMismatch(
            String.self,
            DecodingError.Context(codingPath: codingPath + [key], debugDescription: "Expected String-compatible value.")
        )
    }

    func decodeFlexibleOptionalString(forKey key: Key) throws -> String? {
        guard contains(key) else { return nil }
        if (try? decodeNil(forKey: key)) == true { return nil }
        return try decodeFlexibleString(forKey: key)
    }

    func decodeFlexibleOptionalDouble(forKey key: Key) throws -> Double? {
        guard contains(key) else { return nil }
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return Double(value)
        }
        if let value = try? decode(String.self, forKey: key) {
            return Double(value)
        }
        return nil
    }

    func decodeFlexibleOptionalBool(forKey key: Key) throws -> Bool? {
        guard contains(key) else { return nil }
        if (try? decodeNil(forKey: key)) == true { return nil }
        if let value = try? decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return value != 0
        }
        if let value = try? decode(String.self, forKey: key) {
            switch value.lowercased() {
            case "true", "1":
                return true
            case "false", "0":
                return false
            default:
                return nil
            }
        }
        return nil
    }
}

private struct APIPageResponse<Item: Decodable>: Decodable {
    let hasNext: Bool
    let nextCursor: String?
    let items: [Item]
}

private struct APIBookDTO: Decodable {
    let isbn: String
    let title: String?
    let author: String?
    let publisher: String?
    let description: String?
    let publicationDate: String?
    let coverImageURLString: String?

    enum CodingKeys: String, CodingKey {
        case isbn
        case title
        case author
        case publisher
        case description
        case publicationDate
        case coverImageURLString = "coverImageUrl"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isbn = try container.decodeFlexibleString(forKey: .isbn)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        publicationDate = try container.decodeFlexibleOptionalString(forKey: .publicationDate)
        coverImageURLString = try container.decodeFlexibleOptionalString(forKey: .coverImageURLString)
    }

    func toSummary() -> BookSummary {
        BookSummary(
            id: isbn,
            title: nonEmpty(title, placeholder: "API 응답 필드 추가 필요(책 제목)"),
            author: nonEmpty(author, placeholder: "API 응답 필드 추가 필요(저자)"),
            publisher: nonEmpty(publisher, placeholder: "API 응답 필드 추가 필요(출판사)"),
            year: publicationYearText(from: publicationDate),
            coverImageURL: coverImageURLString.flatMap(URL.init(string:)),
            isFavorite: false,
            isAlertEnabled: false,
            loanStatus: nil
        )
    }

    func toDetail() -> BookDetail {
        BookDetail(
            id: isbn,
            title: nonEmpty(title, placeholder: "API 응답 필드 추가 필요(책 제목)"),
            author: nonEmpty(author, placeholder: "API 응답 필드 추가 필요(저자)"),
            publisher: nonEmpty(publisher, placeholder: "API 응답 필드 추가 필요(출판사)"),
            year: publicationYearText(from: publicationDate),
            coverImageURL: coverImageURLString.flatMap(URL.init(string:)),
            summary: nonEmpty(description?.normalizedMultilineText, placeholder: "API 응답 필드 추가 필요(도서 설명)")
        )
    }
}

private struct APINearbyLibraryDTO: Decodable {
    let libraryId: String
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let homepageURLString: String?
    let tel: String?
    let distanceKm: Double?
    let openNow: Bool

    enum CodingKeys: String, CodingKey {
        case libraryId
        case name
        case address
        case latitude
        case longitude
        case homepageURLString = "homepageUrl"
        case tel
        case distanceKm
        case openNow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        libraryId = try container.decodeFlexibleString(forKey: .libraryId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        latitude = try container.decodeFlexibleOptionalDouble(forKey: .latitude)
        longitude = try container.decodeFlexibleOptionalDouble(forKey: .longitude)
        homepageURLString = try container.decodeFlexibleOptionalString(forKey: .homepageURLString)
        tel = try container.decodeFlexibleOptionalString(forKey: .tel)
        distanceKm = try container.decodeFlexibleOptionalDouble(forKey: .distanceKm)
        openNow = try container.decode(Bool.self, forKey: .openNow)
    }

    func toSummary(loanStatus: LoanStatus? = nil) -> LibrarySummary {
        LibrarySummary(
            id: libraryId,
            name: nonEmpty(name, placeholder: "API 응답 필드 추가 필요(도서관명)"),
            address: nonEmpty(address, placeholder: "API 응답 필드 추가 필요(도서관 주소)"),
            phone: nonEmpty(tel, placeholder: "API 응답 필드 추가 필요(도서관 전화번호)"),
            distanceText: distanceText(from: distanceKm),
            operatingStatus: openNow ? .open : .closed,
            loanStatus: loanStatus,
            isFavorite: false,
            isAlertEnabled: false
        )
    }
}

private struct APIBookAvailabilityDTO: Decodable {
    let libraryId: String
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let distanceKm: Double?
    let hasBook: Bool?
    let loanAvailable: Bool?
    let availabilityStatus: String?
    let openNow: Bool

    enum CodingKeys: String, CodingKey {
        case libraryId
        case name
        case address
        case latitude
        case longitude
        case distanceKm
        case hasBook
        case loanAvailable
        case availabilityStatus
        case openNow
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        libraryId = try container.decodeFlexibleString(forKey: .libraryId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        latitude = try container.decodeFlexibleOptionalDouble(forKey: .latitude)
        longitude = try container.decodeFlexibleOptionalDouble(forKey: .longitude)
        distanceKm = try container.decodeFlexibleOptionalDouble(forKey: .distanceKm)
        hasBook = try container.decodeFlexibleOptionalBool(forKey: .hasBook)
        loanAvailable = try container.decodeFlexibleOptionalBool(forKey: .loanAvailable)
        availabilityStatus = try container.decodeFlexibleOptionalString(forKey: .availabilityStatus)
        openNow = try container.decode(Bool.self, forKey: .openNow)
    }

    var shouldDisplay: Bool {
        inferredHasBook != false
    }

    var matchesAvailableOnly: Bool {
        loanAvailable == true
    }

    func toSummary() -> LibrarySummary {
        LibrarySummary(
            id: libraryId,
            name: nonEmpty(name, placeholder: "API 응답 필드 추가 필요(도서관명)"),
            address: nonEmpty(address, placeholder: "API 응답 필드 추가 필요(도서관 주소)"),
            phone: "",
            distanceText: distanceText(from: distanceKm),
            operatingStatus: openNow ? .open : .closed,
            loanStatus: inferredLoanStatus,
            isFavorite: false,
            isAlertEnabled: false
        )
    }

    private var inferredHasBook: Bool? {
        if let hasBook {
            return hasBook
        }
        switch availabilityStatus?.uppercased() {
        case "AVAILABLE":
            return true
        case "UNAVAILABLE":
            return false
        default:
            return nil
        }
    }

    private var inferredLoanStatus: LoanStatus? {
        guard let loanAvailable else { return nil }
        return loanAvailable ? .available : .borrowed
    }
}

private struct APILibraryDetailDTO: Decodable {
    let libraryId: String
    let name: String?
    let address: String?
    let latitude: Double?
    let longitude: Double?
    let homepageURLString: String?
    let tel: String?
    let openNow: Bool
    let todayOperatingHour: APIOperatingHourDTO?
    let weeklyOperatingHours: [APIOperatingHourDTO]
    let closedRules: [APIClosedRuleDTO]

    enum CodingKeys: String, CodingKey {
        case libraryId
        case name
        case address
        case latitude
        case longitude
        case homepageURLString = "homepageUrl"
        case tel
        case openNow
        case todayOperatingHour
        case weeklyOperatingHours
        case closedRules
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        libraryId = try container.decodeFlexibleString(forKey: .libraryId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        latitude = try container.decodeFlexibleOptionalDouble(forKey: .latitude)
        longitude = try container.decodeFlexibleOptionalDouble(forKey: .longitude)
        homepageURLString = try container.decodeFlexibleOptionalString(forKey: .homepageURLString)
        tel = try container.decodeFlexibleOptionalString(forKey: .tel)
        openNow = try container.decode(Bool.self, forKey: .openNow)
        todayOperatingHour = try container.decodeIfPresent(APIOperatingHourDTO.self, forKey: .todayOperatingHour)
        weeklyOperatingHours = try container.decodeIfPresent([APIOperatingHourDTO].self, forKey: .weeklyOperatingHours) ?? []
        closedRules = try container.decodeIfPresent([APIClosedRuleDTO].self, forKey: .closedRules) ?? []
    }

    func toModel() -> LibraryDetail {
        let weeklyHours = weeklyOperatingHours.sorted { $0.sortKey < $1.sortKey }.map { $0.toModel() }
        let hours: [OperatingHour]
        if weeklyHours.isEmpty {
            hours = [todayOperatingHour?.toTodayModel() ?? OperatingHour(day: "오늘", hoursText: "API 응답 필드 추가 필요(운영 시간)", isClosed: false)]
        } else {
            hours = weeklyHours
        }
        let regularHolidays = closedRules.compactMap { $0.toHolidayEntry() }
        let regularHolidayEntries = regularHolidays.isEmpty
            ? [HolidayEntry(title: "정기 휴관일 정보 없음")]
            : regularHolidays

        return LibraryDetail(
            id: libraryId,
            name: nonEmpty(name, placeholder: "API 응답 필드 추가 필요(도서관명)"),
            address: nonEmpty(address, placeholder: "API 응답 필드 추가 필요(도서관 주소)"),
            phone: nonEmpty(tel, placeholder: "API 응답 필드 추가 필요(도서관 전화번호)"),
            hours: hours,
            regularHolidays: regularHolidayEntries,
            upcomingHolidays: [HolidayEntry(title: "API 응답 필드 추가 필요(예정된 휴관일)")],
            mapDescription: mapDescription(latitude: latitude, longitude: longitude, homepageURLString: homepageURLString)
        )
    }
}

private struct APIOperatingHourDTO: Decodable {
    let weekday: Int?
    let openTime: String?
    let closeTime: String?
    let closed: Bool

    enum CodingKeys: String, CodingKey {
        case weekday
        case openTime
        case closeTime
        case closed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let weekdayString = try container.decodeFlexibleOptionalString(forKey: .weekday) {
            weekday = Int(weekdayString)
        } else {
            weekday = nil
        }
        openTime = try container.decodeIfPresent(String.self, forKey: .openTime)
        closeTime = try container.decodeIfPresent(String.self, forKey: .closeTime)
        closed = try container.decode(Bool.self, forKey: .closed)
    }

    var sortKey: Int {
        weekday ?? .max
    }

    func toModel() -> OperatingHour {
        OperatingHour(
            day: weekdayTitle(for: weekday),
            hoursText: operatingText,
            isClosed: closed
        )
    }

    func toTodayModel() -> OperatingHour {
        OperatingHour(day: "오늘", hoursText: operatingText, isClosed: closed)
    }

    private var operatingText: String {
        if closed {
            return "휴관"
        }
        if let openTime, let closeTime, openTime.isEmpty == false, closeTime.isEmpty == false {
            return "\(openTime) - \(closeTime)"
        }
        return "API 응답 필드 추가 필요(운영 시간)"
    }
}

private struct APIClosedRuleDTO: Decodable {
    let ruleType: String?
    let weekday: Int?
    let nthWeek: Int?
    let monthDay: Int?

    enum CodingKeys: String, CodingKey {
        case ruleType
        case weekday
        case nthWeek
        case monthDay
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ruleType = try container.decodeFlexibleOptionalString(forKey: .ruleType)
        if let weekdayString = try container.decodeFlexibleOptionalString(forKey: .weekday) {
            weekday = Int(weekdayString)
        } else {
            weekday = nil
        }
        if let nthWeekString = try container.decodeFlexibleOptionalString(forKey: .nthWeek) {
            nthWeek = Int(nthWeekString)
        } else {
            nthWeek = nil
        }
        if let monthDayString = try container.decodeFlexibleOptionalString(forKey: .monthDay) {
            monthDay = Int(monthDayString)
        } else {
            monthDay = nil
        }
    }

    func toHolidayEntry() -> HolidayEntry? {
        if let nthWeek, let weekday {
            return HolidayEntry(title: "매월 \(ordinalText(for: nthWeek)) \(weekdayTitle(for: weekday))")
        }
        if let monthDay {
            return HolidayEntry(title: "매월 \(monthDay)일")
        }
        if let weekday {
            return HolidayEntry(title: "매주 \(weekdayTitle(for: weekday))")
        }
        if let ruleType, ruleType.isEmpty == false {
            return HolidayEntry(title: "정기 휴관일(\(ruleType))")
        }
        return nil
    }
}

private func nonEmpty(_ value: String?, placeholder: String) -> String {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), value.isEmpty == false else {
        return placeholder
    }
    return value
}

private func publicationYearText(from rawValue: String?) -> String {
    let digits = rawValue?.filter(\.isNumber) ?? ""
    guard digits.count >= 4 else {
        return "API 응답 필드 추가 필요(출판일)"
    }
    return String(digits.prefix(4))
}

private func distanceText(from distanceKm: Double?) -> String {
    guard let distanceKm else {
        return "API 응답 필드 추가 필요(거리)"
    }
    if distanceKm >= 10 {
        return String(format: "%.0fkm", distanceKm)
    }
    return String(format: "%.1fkm", distanceKm)
}

private func mapDescription(latitude: Double?, longitude: Double?, homepageURLString: String?) -> String {
    var lines: [String] = []
    if let latitude, let longitude {
        lines.append(String(format: "위도 %.4f · 경도 %.4f", latitude, longitude))
    } else {
        lines.append("API 응답 필드 추가 필요(도서관 좌표)")
    }
    if let homepageURLString = homepageURLString?.trimmingCharacters(in: .whitespacesAndNewlines),
       homepageURLString.isEmpty == false {
        lines.append("홈페이지: \(homepageURLString)")
    }
    return lines.joined(separator: "\n")
}

private func weekdayTitle(for weekday: Int?) -> String {
    switch weekday {
    case 1:
        return "월요일"
    case 2:
        return "화요일"
    case 3:
        return "수요일"
    case 4:
        return "목요일"
    case 5:
        return "금요일"
    case 6:
        return "토요일"
    case 7:
        return "일요일"
    default:
        return "요일 정보 없음"
    }
}

private func ordinalText(for number: Int) -> String {
    switch number {
    case 1:
        return "첫째"
    case 2:
        return "둘째"
    case 3:
        return "셋째"
    case 4:
        return "넷째"
    case 5:
        return "다섯째"
    default:
        return "\(number)번째"
    }
}

private extension String {
    var normalizedMultilineText: String {
        replacingOccurrences(of: "\r\n", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension DistanceOption {
    var radiusQueryValue: String {
        switch self {
        case .threeKm:
            return "3"
        case .tenKm:
            return "10"
        case .twentyKm:
            return "20"
        }
    }
}

struct LiveSearchRepository: SearchRepository {
    private let apiClient: PolarisAPIClient

    init(apiClient: PolarisAPIClient) {
        self.apiClient = apiClient
    }

    func searchBooks(query: String) async -> [BookSummary] {
        guard query.isEmpty == false else { return [] }

        let response: APIPageResponse<APIBookDTO>? = await apiClient.get(
            "books/search",
            queryItems: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "limit", value: "10")
            ]
        )

        return response?.items.map { $0.toSummary() } ?? []
    }
}

struct LiveBookRepository: BookRepository {
    private let apiClient: PolarisAPIClient

    init(apiClient: PolarisAPIClient) {
        self.apiClient = apiClient
    }

    func fetchBookDetail(id: String) async -> BookDetail? {
        let book: APIBookDTO? = await apiClient.get("books/\(id)")
        return book?.toDetail()
    }
}

struct LiveLibraryRepository: LibraryRepository {
    private let apiClient: PolarisAPIClient

    init(apiClient: PolarisAPIClient) {
        self.apiClient = apiClient
    }

    func fetchHomeLibraries(origin: AddressSuggestion, distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary] {
        guard let latitude = origin.latitude, let longitude = origin.longitude else { return [] }

        let response: APIPageResponse<APINearbyLibraryDTO>? = await apiClient.get(
            "libraries/nearby",
            queryItems: [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "radiusKm", value: distance.radiusQueryValue),
                URLQueryItem(name: "limit", value: "20")
            ]
        )

        let items = response?.items ?? []
        let filtered = excludeClosed ? items.filter(\.openNow) : items
        return filtered.map { $0.toSummary() }
    }

    func fetchNearbyLibraries(origin: AddressSuggestion, distance: DistanceOption, query: SearchQuery, selectedBookID: String?) async -> [LibrarySummary] {
        guard let latitude = origin.latitude, let longitude = origin.longitude else { return [] }

        if let selectedBookID, selectedBookID.isEmpty == false {
            let response: APIPageResponse<APIBookAvailabilityDTO>? = await apiClient.get(
                "book-availability",
                queryItems: [
                    URLQueryItem(name: "isbn", value: selectedBookID),
                    URLQueryItem(name: "latitude", value: String(latitude)),
                    URLQueryItem(name: "longitude", value: String(longitude)),
                    URLQueryItem(name: "radiusKm", value: distance.radiusQueryValue),
                    query.excludeUnavailable ? URLQueryItem(name: "loanAvailable", value: "true") : URLQueryItem(name: "loanAvailable", value: nil),
                    URLQueryItem(name: "limit", value: "20")
                ]
            )

            return (response?.items ?? [])
                .filter(\.shouldDisplay)
                .filter { query.excludeUnavailable == false || $0.matchesAvailableOnly }
                .map { $0.toSummary() }
        }

        let response: APIPageResponse<APINearbyLibraryDTO>? = await apiClient.get(
            "libraries/nearby",
            queryItems: [
                URLQueryItem(name: "latitude", value: String(latitude)),
                URLQueryItem(name: "longitude", value: String(longitude)),
                URLQueryItem(name: "radiusKm", value: distance.radiusQueryValue),
                URLQueryItem(name: "limit", value: "20")
            ]
        )

        return response?.items.map { $0.toSummary() } ?? []
    }

    func fetchLibraryDetail(id: String) async -> LibraryDetail? {
        let detail: APILibraryDetailDTO? = await apiClient.get("libraries/\(id)")
        return detail?.toModel()
    }
}

struct UnavailableFavoritesRepository: FavoritesRepository {
    func fetchFavoriteBooks() async -> [BookSummary] {
        []
    }

    func fetchFavoriteLibraries() async -> [LibrarySummary] {
        []
    }
}

struct UnavailableAlertsRepository: AlertsRepository {
    func fetchAlerts() async -> [AlertItem] {
        []
    }
}

struct UnavailableProfileRepository: ProfileRepository {
    func fetchProfile() async -> UserProfile {
        UserProfile(
            name: "API 미구현(로그인 사용자)",
            subtitle: "User(로그인) API 미구현",
            headline: "로그인/사용자 정보 API가 아직 제공되지 않았습니다.",
            location: "API 미구현(사용자 위치)"
        )
    }
}

private enum MockFixture {
    static let books: [BookSummary] = [
        BookSummary(id: "book-arond-1", title: "아몬드", author: "손원평", publisher: "창비", year: "2024", coverImageURL: nil, isFavorite: true, isAlertEnabled: true, loanStatus: .borrowed),
        BookSummary(id: "book-arond-2", title: "아몬드", author: "홍길동", publisher: "개발출판사", year: "2024", coverImageURL: nil, isFavorite: true, isAlertEnabled: false, loanStatus: .borrowed),
        BookSummary(id: "book-arond-3", title: "아몬드", author: "홍길동", publisher: "개발출판사", year: "2024", coverImageURL: nil, isFavorite: false, isAlertEnabled: false, loanStatus: nil)
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
        "book-arond-1": ["library-gangnam", "library-daechi", "library-gumi-central", "library-geumo"],
        "book-arond-2": ["library-gangnam", "library-yeoksam", "library-gumi-central", "library-hyeonggok"],
        "book-arond-3": ["library-daechi", "library-suseo", "library-geumo", "library-indong"]
    ]

    static let alerts: [AlertItem] = [
        AlertItem(
            id: "alert-1",
            section: .available,
            book: BookSummary(id: "alert-book-1", title: "아몬드", author: "김철수", publisher: "인사이트", year: "2024", coverImageURL: nil, isFavorite: true, isAlertEnabled: true, loanStatus: .available),
            libraryName: "강남 도서관"
        ),
        AlertItem(
            id: "alert-2",
            section: .waiting,
            book: BookSummary(id: "alert-book-2", title: "아몬드", author: "김철수", publisher: "인사이트", year: "2024", coverImageURL: nil, isFavorite: false, isAlertEnabled: true, loanStatus: .notificationReady),
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
        coverImageURL: nil,
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
            coverImageURL: nil,
            summary: MockFixture.bookDetail.summary
        )
    }
}

struct MockLibraryRepository: LibraryRepository {
    func fetchHomeLibraries(origin: AddressSuggestion, distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary] {
        let sourceLibraries = origin.roadAddress.contains("구미") ? MockFixture.gumiLibraries : MockFixture.libraries
        let filteredByDistance: [LibrarySummary]
        switch distance {
        case .threeKm:
            filteredByDistance = Array(sourceLibraries.prefix(2))
        case .tenKm:
            filteredByDistance = Array(sourceLibraries.prefix(3))
        case .twentyKm:
            filteredByDistance = sourceLibraries
        }

        if excludeClosed {
            return filteredByDistance.filter { $0.operatingStatus == .open }
        }

        return filteredByDistance
    }

    func fetchNearbyLibraries(origin: AddressSuggestion, distance: DistanceOption, query: SearchQuery, selectedBookID: String?) async -> [LibrarySummary] {
        let sourceLibraries = origin.roadAddress.contains("구미") ? MockFixture.gumiLibraries : MockFixture.libraries
        let distanceFiltered: [LibrarySummary]
        switch distance {
        case .threeKm:
            distanceFiltered = Array(sourceLibraries.prefix(2))
        case .tenKm:
            distanceFiltered = Array(sourceLibraries.prefix(3))
        case .twentyKm:
            distanceFiltered = sourceLibraries
        }

        let filtered: [LibrarySummary]
        if let selectedBookID, let libraryIDs = MockFixture.bookHoldings[selectedBookID] {
            filtered = distanceFiltered.filter { libraryIDs.contains($0.id) }
        } else {
            filtered = distanceFiltered
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
