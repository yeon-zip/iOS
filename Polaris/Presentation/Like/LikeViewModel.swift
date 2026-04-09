//
//  LikeViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class LikeViewModel {
    struct State: Equatable {
        var selectedTab: FavoriteTab = .books
        var books: [FavoriteBookItemViewData] = []
        var libraries: [LibraryCardItemViewData] = []
        var errorMessage: String?
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let favoritesRepository: any FavoritesRepository
    private(set) var state = State()

    init(favoritesRepository: any FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func load() async {
        state.errorMessage = nil
        onStateChange?(state)

        let fetchedBooks: [BookSummary]
        let fetchedLibraries: [LibrarySummary]
        do {
            fetchedBooks = try await favoritesRepository.fetchFavoriteBooks()
            fetchedLibraries = try await favoritesRepository.fetchFavoriteLibraries()
        } catch {
            state.books = []
            state.libraries = []
            state.errorMessage = "찜 목록을 불러오지 못했습니다."
            onStateChange?(state)
            return
        }

        state.books = fetchedBooks.map { book in
            FavoriteBookItemViewData(
                id: book.id,
                title: book.title,
                subtitle: bookSubtitle(for: book),
                coverImageURL: book.coverImageURL,
                badges: book.loanStatus.map { [makeLoanBadge($0)] } ?? [],
                isAlertEnabled: book.isAlertEnabled,
                isFavorite: book.isFavorite
            )
        }
        state.libraries = fetchedLibraries.map { library in
            LibraryCardItemViewData(
                id: library.id,
                title: library.name,
                distanceText: library.distanceText,
                badges: [BadgeContent(title: "찜한 도서관", tone: .blue)],
                showsBell: true,
                showsFavorite: true,
                isBellActive: library.isAlertEnabled,
                isFavorite: library.isFavorite
            )
        }
        onStateChange?(state)
    }

    func didTapBack() {
        onRoute?(.back)
    }

    func didSelectTab(index: Int) {
        guard let tab = FavoriteTab(rawValue: index) else { return }
        state.selectedTab = tab
        onStateChange?(state)
    }

    func didSelectBook(id: String) {
        guard let book = state.books.first(where: { $0.id == id }) else { return }
        onRoute?(.bookSearch(query: book.title))
    }

    func didTapBookDetail(id: String) {
        onRoute?(.bookDetail(id: id))
    }

    func didSelectLibrary(id: String) {
        onRoute?(.libraryDetail(id: id))
    }

    func didToggleBookFavorite(id: String) async {
        guard let index = state.books.firstIndex(where: { $0.id == id }) else { return }
        let item = state.books[index]
        let previousBooks = state.books
        let nextFavoriteState = item.isFavorite == false

        if nextFavoriteState {
            state.books[index] = FavoriteBookItemViewData(
                id: item.id,
                title: item.title,
                subtitle: item.subtitle,
                coverImageURL: item.coverImageURL,
                badges: item.badges,
                isAlertEnabled: item.isAlertEnabled,
                isFavorite: true
            )
        } else {
            state.books.remove(at: index)
        }
        state.errorMessage = nil
        onStateChange?(state)

        do {
            try await favoritesRepository.setBookFavorite(id: id, isFavorite: nextFavoriteState)
        } catch {
            state.books = previousBooks
            state.errorMessage = "도서 찜 상태를 변경하지 못했습니다."
            onStateChange?(state)
            return
        }
    }

    func didToggleBookAlert(id: String) {
        guard let index = state.books.firstIndex(where: { $0.id == id }) else { return }
        let item = state.books[index]
        state.books[index] = FavoriteBookItemViewData(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            coverImageURL: item.coverImageURL,
            badges: item.badges,
            isAlertEnabled: item.isAlertEnabled == false,
            isFavorite: item.isFavorite
        )
        onStateChange?(state)
    }

    func didToggleLibraryFavorite(id: String) async {
        guard let index = state.libraries.firstIndex(where: { $0.id == id }) else { return }
        let item = state.libraries[index]
        let previousLibraries = state.libraries
        let nextFavoriteState = item.isFavorite == false

        if nextFavoriteState {
            state.libraries[index] = LibraryCardItemViewData(
                id: item.id,
                title: item.title,
                distanceText: item.distanceText,
                badges: item.badges,
                showsBell: item.showsBell,
                showsFavorite: item.showsFavorite,
                isBellActive: item.isBellActive,
                isFavorite: true
            )
        } else {
            state.libraries.remove(at: index)
        }
        state.errorMessage = nil
        onStateChange?(state)

        do {
            try await favoritesRepository.setLibraryFavorite(id: id, isFavorite: nextFavoriteState)
        } catch {
            state.libraries = previousLibraries
            state.errorMessage = "도서관 찜 상태를 변경하지 못했습니다."
            onStateChange?(state)
            return
        }
    }

    private func bookSubtitle(for book: BookSummary) -> String {
        let parts = [book.author, book.publisher]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
        return parts.isEmpty ? "ISBN \(book.id)" : parts.joined(separator: " · ")
    }
}
