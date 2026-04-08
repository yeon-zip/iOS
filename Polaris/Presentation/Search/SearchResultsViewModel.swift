//
//  SearchResultsViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class SearchResultsViewModel {
    struct State: Equatable {
        var query = SearchQuery(text: "", excludeUnavailable: false)
        var selectedBookID: String?
        var books: [BookCarouselItemViewData] = []
        var libraries: [LibraryCardItemViewData] = []
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let searchRepository: any SearchRepository
    private let libraryRepository: any LibraryRepository
    private(set) var state = State()
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init(searchRepository: any SearchRepository, libraryRepository: any LibraryRepository) {
        self.searchRepository = searchRepository
        self.libraryRepository = libraryRepository
    }

    func load() async {
        await refresh(request: currentRequest, generation: nil)
    }

    func didTapBack() {
        onRoute?(.back)
    }

    @discardableResult
    func didSubmitQuery(_ query: String) -> Task<Void, Never> {
        state.query.text = query
        state.selectedBookID = nil
        state.books = state.books.map { item in
            BookCarouselItemViewData(
                id: item.id,
                title: item.title,
                subtitle: item.subtitle,
                isFeatured: item.isFeatured,
                isSelected: false
            )
        }
        onStateChange?(state)
        return scheduleRefresh()
    }

    @discardableResult
    func didToggleExcludeUnavailable(_ isOn: Bool) -> Task<Void, Never> {
        state.query.excludeUnavailable = isOn
        onStateChange?(state)
        return scheduleRefresh()
    }

    @discardableResult
    func didSelectBook(id: String) -> Task<Void, Never> {
        state.selectedBookID = id
        state.books = state.books.map { item in
            BookCarouselItemViewData(
                id: item.id,
                title: item.title,
                subtitle: item.subtitle,
                isFeatured: item.isFeatured,
                isSelected: item.id == id
            )
        }
        onStateChange?(state)
        return scheduleRefresh()
    }

    func didTapBookDetail(id: String) {
        onRoute?(.bookDetail(id: id))
    }

    func didSelectLibrary(id: String) {
        onRoute?(.libraryDetail(id: id))
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
            isBellActive: item.isBellActive,
            isFavorite: item.isFavorite == false
        )
        onStateChange?(state)
    }

    func didToggleLibraryAlert(id: String) {
        guard let index = state.libraries.firstIndex(where: { $0.id == id }) else { return }
        let item = state.libraries[index]
        state.libraries[index] = LibraryCardItemViewData(
            id: item.id,
            title: item.title,
            distanceText: item.distanceText,
            badges: item.badges,
            showsBell: item.showsBell,
            isBellActive: item.isBellActive == false,
            isFavorite: item.isFavorite
        )
        onStateChange?(state)
    }

    private var currentRequest: SearchResultsRequest {
        SearchResultsRequest(query: state.query, selectedBookID: state.selectedBookID)
    }

    private func scheduleRefresh() -> Task<Void, Never> {
        refreshGeneration += 1
        let generation = refreshGeneration
        let request = currentRequest
        refreshTask?.cancel()
        let task: Task<Void, Never> = Task { [weak self] in
            guard let self else { return }
            await self.refresh(request: request, generation: generation)
        }
        refreshTask = task
        return task
    }

    private func refresh(request: SearchResultsRequest, generation: Int?) async {
        let fetchedBooks = await searchRepository.searchBooks(query: request.query.text)
        let effectiveSelectedBookID: String?
        if let selectedBookID = request.selectedBookID,
           fetchedBooks.contains(where: { $0.id == selectedBookID }) {
            effectiveSelectedBookID = selectedBookID
        } else {
            effectiveSelectedBookID = nil
        }
        let fetchedLibraries = await libraryRepository.fetchNearbyLibraries(
            query: request.query,
            selectedBookID: effectiveSelectedBookID
        )
        guard Task.isCancelled == false else { return }
        if let generation {
            guard generation == refreshGeneration, request == currentRequest else { return }
        }

        state.selectedBookID = effectiveSelectedBookID
        state.books = fetchedBooks.enumerated().map { index, book in
            BookCarouselItemViewData(
                id: book.id,
                title: book.title,
                subtitle: "저자: \(book.author)",
                isFeatured: index == 0,
                isSelected: book.id == effectiveSelectedBookID
            )
        }
        state.libraries = fetchedLibraries.map { library in
            var badges = [makeOperatingBadge(library.operatingStatus)]
            if let loanStatus = library.loanStatus {
                badges.append(makeLoanBadge(loanStatus))
            }
            return LibraryCardItemViewData(
                id: library.id,
                title: library.name,
                distanceText: library.distanceText,
                badges: badges,
                showsBell: true,
                isBellActive: library.isAlertEnabled,
                isFavorite: library.isFavorite
            )
        }
        onStateChange?(state)
    }
}

private struct SearchResultsRequest: Equatable {
    let query: SearchQuery
    let selectedBookID: String?
}
