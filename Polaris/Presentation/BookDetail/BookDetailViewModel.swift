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
    }

    var onStateChange: ((State) -> Void)?

    private let bookID: String
    private let bookRepository: any BookRepository
    private(set) var state = State()

    init(bookID: String, bookRepository: any BookRepository) {
        self.bookID = bookID
        self.bookRepository = bookRepository
    }

    func load() async {
        state.detail = await bookRepository.fetchBookDetail(id: bookID)
        onStateChange?(state)
    }
}
