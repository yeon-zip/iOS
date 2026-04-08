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
        var selectedDistance: DistanceOption = .oneKm
        var excludeClosed = false
        var libraries: [LibraryCardItemViewData] = []
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let libraryRepository: any LibraryRepository
    private(set) var state = State()
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init(libraryRepository: any LibraryRepository) {
        self.libraryRepository = libraryRepository
    }

    func load() async {
        await refreshLibraries(request: currentRequest, generation: nil)
    }

    func didTapSearch() {
        onRoute?(.search)
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

    func didToggleFavorite(id: String) {
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
                showsBell: false,
                isBellActive: library.isAlertEnabled,
                isFavorite: library.isFavorite
            )
        }
        onStateChange?(state)
    }
}

private struct HomeLibrariesRequest: Equatable {
    let origin: AddressSuggestion
    let distance: DistanceOption
    let excludeClosed: Bool
}
