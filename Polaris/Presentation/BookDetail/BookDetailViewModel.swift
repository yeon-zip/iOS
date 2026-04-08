//
//  BookDetailViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class BookDetailViewModel {
    struct State: Equatable {
        var detail: BookDetail?
        var isFavorite = false
        var isMutatingFavorite = false
        var errorMessage: String?
    }

    var onStateChange: ((State) -> Void)?

    private let bookID: String
    private let bookRepository: any BookRepository
    private let favoritesRepository: any FavoritesRepository
    private(set) var state = State()

    init(
        bookID: String,
        bookRepository: any BookRepository,
        favoritesRepository: any FavoritesRepository = UnavailableFavoritesRepository()
    ) {
        self.bookID = bookID
        self.bookRepository = bookRepository
        self.favoritesRepository = favoritesRepository
    }

    func load() async {
        guard let detail = await bookRepository.fetchBookDetail(id: bookID) else {
            state.detail = nil
            onStateChange?(state)
            return
        }

        state.detail = detail
        let favoriteBookIDs = await loadFavoriteBookIDs()
        state.isFavorite = detail.isFavorite || favoriteBookIDs.contains(detail.id)
        state.errorMessage = nil
        onStateChange?(state)
    }

    func didTapFavorite() async {
        guard let detail = state.detail, state.isMutatingFavorite == false else { return }

        let previousFavoriteState = state.isFavorite
        let nextFavoriteState = previousFavoriteState == false
        state.isFavorite = nextFavoriteState
        state.isMutatingFavorite = true
        state.errorMessage = nil
        onStateChange?(state)

        do {
            try await favoritesRepository.setBookFavorite(id: detail.id, isFavorite: nextFavoriteState)
            state.isMutatingFavorite = false
            onStateChange?(state)
        } catch {
            state.isFavorite = previousFavoriteState
            state.isMutatingFavorite = false
            state.errorMessage = "책 찜 상태를 변경하지 못했습니다."
            onStateChange?(state)
        }
    }

    private func loadFavoriteBookIDs() async -> Set<String> {
        do {
            return Set(try await favoritesRepository.fetchFavoriteBooks().map(\.id))
        } catch {
            return []
        }
    }
}
