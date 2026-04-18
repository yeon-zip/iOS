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
        var selectedDistance: DistanceOption
        var selectedBookID: String?
        var books: [BookCarouselItemViewData] = []
        var libraries: [LibraryCardItemViewData] = []
        var isBooksLoading = false
        var isLibrariesLoading = false
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let searchRepository: any SearchRepository
    private let libraryRepository: any LibraryRepository
    private var currentLocation: AddressSuggestion
    private(set) var state: State
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init(
        searchRepository: any SearchRepository,
        libraryRepository: any LibraryRepository,
        currentLocation: AddressSuggestion,
        currentDistance: DistanceOption,
        initialQuery: String? = nil
    ) {
        self.searchRepository = searchRepository
        self.libraryRepository = libraryRepository
        self.currentLocation = currentLocation
        self.state = State(selectedDistance: currentDistance)
        self.state.query.text = initialQuery?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func load() async {
        await scheduleFullRefresh().value
    }

    func didTapBack() {
        onRoute?(.back)
    }

    @discardableResult
    func didUpdateLocation(_ location: AddressSuggestion) -> Task<Void, Never>? {
        currentLocation = location
        guard state.query.text.isEmpty == false else { return nil }
        return scheduleLibrariesRefresh()
    }

    @discardableResult
    func didSubmitQuery(_ query: String) -> Task<Void, Never> {
        state.query.text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        state.query.excludeUnavailable = false
        state.selectedBookID = nil
        state.books = state.books.map { item in
            BookCarouselItemViewData(
                id: item.id,
                title: item.title,
                subtitle: item.subtitle,
                coverImageURL: item.coverImageURL,
                isFeatured: item.isFeatured,
                isSelected: false
            )
        }
        onStateChange?(state)
        return scheduleFullRefresh()
    }

    @discardableResult
    func didToggleExcludeUnavailable(_ isOn: Bool) -> Task<Void, Never> {
        state.query.excludeUnavailable = isOn
        onStateChange?(state)
        return scheduleLibrariesRefresh()
    }

    @discardableResult
    func didSelectDistance(_ distance: DistanceOption) -> Task<Void, Never> {
        state.selectedDistance = distance
        onStateChange?(state)
        return scheduleLibrariesRefresh()
    }

    @discardableResult
    func didSelectBook(id: String) -> Task<Void, Never> {
        state.selectedBookID = id
        state.books = state.books.map { item in
            BookCarouselItemViewData(
                id: item.id,
                title: item.title,
                subtitle: item.subtitle,
                coverImageURL: item.coverImageURL,
                isFeatured: item.isFeatured,
                isSelected: item.id == id
            )
        }
        onStateChange?(state)
        return scheduleLibrariesRefresh()
    }

    func didTapBookDetail(id: String) {
        onRoute?(.bookDetail(id: id))
    }

    func didSelectLibrary(id: String) {
        onRoute?(.libraryDetail(id: id))
    }

    func didToggleLibraryFavorite(id: String) {
        // Favorites API is not available yet.
    }

    func didToggleLibraryAlert(id: String) {
        // Alerts API is not available yet.
    }

    private var currentRequest: SearchResultsRequest {
        SearchResultsRequest(
            selectedDistance: state.selectedDistance,
            query: state.query,
            selectedBookID: state.selectedBookID
        )
    }

    private func scheduleFullRefresh() -> Task<Void, Never> {
        refreshGeneration += 1
        let generation = refreshGeneration
        let request = currentRequest
        refreshTask?.cancel()
        state.isBooksLoading = true
        state.isLibrariesLoading = true
        state.libraries = []
        onStateChange?(state)
        let task: Task<Void, Never> = Task { [weak self] in
            guard let self else { return }
            await self.refreshBooksAndLibraries(request: request, generation: generation)
        }
        refreshTask = task
        return task
    }

    private func scheduleLibrariesRefresh() -> Task<Void, Never> {
        refreshGeneration += 1
        let generation = refreshGeneration
        let request = currentRequest
        refreshTask?.cancel()
        state.isBooksLoading = false
        state.isLibrariesLoading = true
        state.libraries = []
        onStateChange?(state)
        let task: Task<Void, Never> = Task { [weak self] in
            guard let self else { return }
            await self.refreshLibraries(request: request, generation: generation)
        }
        refreshTask = task
        return task
    }

    private func refreshBooksAndLibraries(request: SearchResultsRequest, generation: Int) async {
        let fetchedBooks = await searchRepository.searchBooks(query: request.query.text)
        guard Task.isCancelled == false, generation == refreshGeneration else { return }

        let effectiveSelectedBookID: String?
        if request.query.text.isEmpty {
            effectiveSelectedBookID = nil
        } else if let selectedBookID = request.selectedBookID,
                  fetchedBooks.contains(where: { $0.id == selectedBookID }) {
            effectiveSelectedBookID = selectedBookID
        } else {
            effectiveSelectedBookID = fetchedBooks.first?.id
        }

        state.selectedBookID = effectiveSelectedBookID
        state.books = fetchedBooks.enumerated().map { index, book in
            BookCarouselItemViewData(
                id: book.id,
                title: book.title,
                subtitle: "저자: \(book.author)",
                coverImageURL: book.coverImageURL,
                isFeatured: index == 0,
                isSelected: book.id == effectiveSelectedBookID
            )
        }
        state.isBooksLoading = false
        onStateChange?(state)

        let fetchedLibraries = await libraryRepository.fetchNearbyLibraries(
            origin: currentLocation,
            distance: request.selectedDistance,
            query: request.query,
            selectedBookID: effectiveSelectedBookID
        )
        guard Task.isCancelled == false, generation == refreshGeneration else { return }
        applyLibraries(fetchedLibraries)
    }

    private func refreshLibraries(request: SearchResultsRequest, generation: Int) async {
        let fetchedLibraries = await libraryRepository.fetchNearbyLibraries(
            origin: currentLocation,
            distance: request.selectedDistance,
            query: request.query,
            selectedBookID: request.selectedBookID
        )
        guard Task.isCancelled == false, generation == refreshGeneration else { return }
        applyLibraries(fetchedLibraries)
    }

    private func applyLibraries(_ fetchedLibraries: [LibrarySummary]) {
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
                showsBell: false,
                showsFavorite: false,
                isBellActive: library.isAlertEnabled,
                isFavorite: library.isFavorite
            )
        }
        state.isLibrariesLoading = false
        onStateChange?(state)
    }
}

private struct SearchResultsRequest: Equatable {
    let selectedDistance: DistanceOption
    let query: SearchQuery
    let selectedBookID: String?
}
