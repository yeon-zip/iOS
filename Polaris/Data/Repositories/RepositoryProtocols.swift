import Foundation

protocol SearchRepository {
    func searchBooks(query: String) async -> [BookSummary]
}

protocol BookRepository {
    func fetchBookDetail(id: String) async -> BookDetail?
}

protocol BookVoteRepository {
    func voteBook(id: String, voteType: BookVoteType) async throws
}

protocol LibraryRepository {
    func fetchHomeLibraries(origin: AddressSuggestion, distance: DistanceOption, excludeClosed: Bool) async -> [LibrarySummary]
    func fetchNearbyLibraries(origin: AddressSuggestion, distance: DistanceOption, query: SearchQuery, selectedBookID: String?) async -> [LibrarySummary]
    func fetchLibraryDetail(id: String) async -> LibraryDetail?
}

protocol FavoritesRepository {
    func fetchFavoriteBooks() async throws -> [BookSummary]
    func fetchFavoriteLibraries() async throws -> [LibrarySummary]
    func setBookFavorite(id: String, isFavorite: Bool) async throws
    func setLibraryFavorite(id: String, isFavorite: Bool) async throws
}

protocol AlertsRepository {
    func fetchAlerts() async throws -> [AlertItem]
    func fetchAlertSubscriptions() async throws -> [AlertItem]
    func deleteAlert(id: String) async throws
    func setAlertSubscription(bookID: String, libraryID: String, isEnabled: Bool) async throws
}

protocol PushNotificationRepository {
    func registerDeviceToken(_ deviceToken: String) async throws
    func deleteDeviceToken(_ deviceToken: String) async throws
}

protocol ProfileRepository {
    func fetchProfile() async throws -> UserProfile
}

enum RepositoryError: Error, Equatable {
    case unauthenticated
    case unavailable
}

protocol AuthRepository {
    func currentSession() async -> AuthSession?
    func restoreSession() async -> AuthSession?
    func makeKakaoLoginRequest() async throws -> AuthLoginRequest
    func exchange(code: String, targetID: String, codeVerifier: String) async throws -> AuthSession
    func refresh() async throws -> AuthSession
    func logout() async throws
    func clearLocalSession() async
}
