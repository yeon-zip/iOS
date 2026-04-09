//
//  LibraryDetailViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class LibraryDetailViewModel {
    struct State: Equatable {
        var detail: LibraryDetail?
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let libraryID: String
    private let libraryRepository: any LibraryRepository
    private(set) var state = State()

    init(libraryID: String, libraryRepository: any LibraryRepository) {
        self.libraryID = libraryID
        self.libraryRepository = libraryRepository
    }

    func load() async {
        state.detail = await libraryRepository.fetchLibraryDetail(id: libraryID)
        onStateChange?(state)
    }

    func didTapBack() {
        onRoute?(.back)
    }
}
