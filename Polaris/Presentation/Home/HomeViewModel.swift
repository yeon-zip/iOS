//
//  HomeViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class HomeViewModel {
    struct State: Equatable {
        var selectedLocation = AddressSuggestion(
            id: "home-default-location",
            roadAddress: "경상북도 구미시 대학로 61",
            detailText: "기본 위치",
            latitude: 36.1450,
            longitude: 128.3937
        )
        var selectedDistance: DistanceOption = .twoKm
        var excludeClosed = false
        var libraries: [LibraryCardItemViewData] = []
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let libraryRepository: any LibraryRepository
    private let favoritesRepository: any FavoritesRepository
    private(set) var state = State()
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init(
        libraryRepository: any LibraryRepository,
        favoritesRepository: any FavoritesRepository = UnavailableFavoritesRepository()
    ) {
        self.libraryRepository = libraryRepository
        self.favoritesRepository = favoritesRepository
    }

    func load() async {
        await refreshLibraries(request: currentRequest, generation: nil)
    }

    func didTapSearch(initialQuery: String? = nil) {
        onRoute?(.search(
            currentLocation: state.selectedLocation,
            currentDistance: state.selectedDistance,
            initialQuery: initialQuery
        ))
    }

    func didTapLikes() {
        onRoute?(.likes)
    }

    func didTapAlerts() {
        onRoute?(.alerts)
    }

    func didTapProfile() {
        onRoute?(.profile)
    }

    func didTapLocationPicker() {
        onRoute?(.locationPicker(currentLocation: state.selectedLocation))
    }

    @discardableResult
    func didSelectDistance(_ distance: DistanceOption) -> Task<Void, Never> {
        state.selectedDistance = distance
        onStateChange?(state)
        return scheduleRefresh()
    }

    @discardableResult
    func didToggleExcludeClosed(_ isOn: Bool) -> Task<Void, Never> {
        state.excludeClosed = isOn
        onStateChange?(state)
        return scheduleRefresh()
    }

    func didSelectLibrary(id: String) {
        onRoute?(.libraryDetail(id: id))
    }

    @discardableResult
    func didUpdateLocation(_ location: AddressSuggestion) -> Task<Void, Never> {
        state.selectedLocation = location
        onStateChange?(state)
        return scheduleRefresh()
    }

    func didToggleFavorite(id: String) async {
        guard let index = state.libraries.firstIndex(where: { $0.id == id }) else { return }
        let item = state.libraries[index]
        let previousLibraries = state.libraries
        let nextFavoriteState = item.isFavorite == false

        state.libraries[index] = item.withFavoriteState(nextFavoriteState)
        onStateChange?(state)

        do {
            try await favoritesRepository.setLibraryFavorite(id: id, isFavorite: nextFavoriteState)
        } catch {
            state.libraries = previousLibraries
            onStateChange?(state)
        }
    }

    private var currentRequest: HomeLibrariesRequest {
        HomeLibrariesRequest(
            origin: state.selectedLocation,
            distance: state.selectedDistance,
            excludeClosed: state.excludeClosed
        )
    }

    private func scheduleRefresh() -> Task<Void, Never> {
        refreshGeneration += 1
        let generation = refreshGeneration
        let request = currentRequest
        refreshTask?.cancel()
        let task: Task<Void, Never> = Task { [weak self] in
            guard let self else { return }
            await self.refreshLibraries(request: request, generation: generation)
        }
        refreshTask = task
        return task
    }

    private func refreshLibraries(request: HomeLibrariesRequest, generation: Int?) async {
        let libraries = await libraryRepository.fetchHomeLibraries(
            origin: request.origin,
            distance: request.distance,
            excludeClosed: request.excludeClosed
        )
        let favoriteLibraryIDs = await loadFavoriteLibraryIDs()
        guard Task.isCancelled == false else { return }
        if let generation {
            guard generation == refreshGeneration, request == currentRequest else { return }
        }

        state.libraries = libraries.map { library in
            LibraryCardItemViewData(
                id: library.id,
                title: library.name,
                distanceText: library.distanceText,
                badges: [makeOperatingBadge(library.operatingStatus)],
                showsBell: true,
                showsFavorite: true,
                isBellActive: library.isAlertEnabled,
                isFavorite: favoriteLibraryIDs.contains(library.id) || library.isFavorite
            )
        }
        onStateChange?(state)
    }

    private func loadFavoriteLibraryIDs() async -> Set<String> {
        do {
            return Set(try await favoritesRepository.fetchFavoriteLibraries().map(\.id))
        } catch {
            return []
        }
    }
}

private struct HomeLibrariesRequest: Equatable {
    let origin: AddressSuggestion
    let distance: DistanceOption
    let excludeClosed: Bool
}

private extension LibraryCardItemViewData {
    func withFavoriteState(_ isFavorite: Bool) -> LibraryCardItemViewData {
        LibraryCardItemViewData(
            id: id,
            title: title,
            distanceText: distanceText,
            badges: badges,
            showsBell: showsBell,
            showsFavorite: showsFavorite,
            isBellActive: isBellActive,
            isFavorite: isFavorite
        )
    }
}
