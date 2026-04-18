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
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let favoritesRepository: any FavoritesRepository
    private(set) var state = State()

    init(favoritesRepository: any FavoritesRepository) {
        self.favoritesRepository = favoritesRepository
    }

    func load() async {
        async let books = favoritesRepository.fetchFavoriteBooks()
        async let libraries = favoritesRepository.fetchFavoriteLibraries()
        let fetchedBooks = await books
        let fetchedLibraries = await libraries

        state.books = fetchedBooks.map { book in
            FavoriteBookItemViewData(
                id: book.id,
                title: book.title,
                subtitle: "\(book.author) · \(book.publisher)",
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
                badges: [makeOperatingBadge(library.operatingStatus)],
                showsBell: false,
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
        onRoute?(.bookDetail(id: id))
    }

    func didSelectLibrary(id: String) {
        onRoute?(.libraryDetail(id: id))
    }

    func didToggleBookFavorite(id: String) {
        guard let index = state.books.firstIndex(where: { $0.id == id }) else { return }
        let item = state.books[index]
        state.books[index] = FavoriteBookItemViewData(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            badges: item.badges,
            isAlertEnabled: item.isAlertEnabled,
            isFavorite: item.isFavorite == false
        )
        onStateChange?(state)
    }

    func didToggleBookAlert(id: String) {
        guard let index = state.books.firstIndex(where: { $0.id == id }) else { return }
        let item = state.books[index]
        state.books[index] = FavoriteBookItemViewData(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            badges: item.badges,
            isAlertEnabled: item.isAlertEnabled == false,
            isFavorite: item.isFavorite
        )
        onStateChange?(state)
    }

    func didToggleLibraryFavorite(id: String) {
        guard let index = state.libraries.firstIndex(where: { $0.id == id }) else { return }
        let item = state.libraries[index]
        state.libraries[index] = LibraryCardItemViewData(
            id: item.id,
            title: item.title,
            distanceText: item.distanceText,
            badges: item.badges,
            showsBell: item.showsBell,
            showsFavorite: item.showsFavorite,
            isBellActive: item.isBellActive,
            isFavorite: item.isFavorite == false
        )
        onStateChange?(state)
    }
}
