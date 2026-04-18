//
//  AlarmViewModel.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import Foundation

@MainActor
final class AlarmViewModel {
    struct State: Equatable {
        var sections: [AlertSection: [AlertBookItemViewData]] = [:]
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let alertsRepository: any AlertsRepository
    private(set) var state = State()

    init(alertsRepository: any AlertsRepository) {
        self.alertsRepository = alertsRepository
    }

    func load() async {
        let alerts = await alertsRepository.fetchAlerts()
        state.sections = Dictionary(grouping: alerts, by: \.section).mapValues { items in
            items.map { item in
                AlertBookItemViewData(
                    id: item.id,
                    bookID: item.book.id,
                    title: item.book.title,
                    metadataText: "\(item.book.author) · \(item.book.publisher)",
                    libraryName: item.libraryName,
                    badges: item.book.loanStatus.map { [makeLoanBadge($0)] } ?? [],
                    isAlertEnabled: item.book.isAlertEnabled
                )
            }
        }
        onStateChange?(state)
    }

    func didTapBack() {
        onRoute?(.back)
    }

    func didSelectBook(id: String) {
        onRoute?(.bookDetail(id: id))
    }

    func didToggleAlert(id: String) {
        for section in AlertSection.allCases {
            guard let index = state.sections[section]?.firstIndex(where: { $0.id == id }) else { continue }
            guard let item = state.sections[section]?[index] else { continue }
            state.sections[section]?[index] = AlertBookItemViewData(
                id: item.id,
                bookID: item.bookID,
                title: item.title,
                metadataText: item.metadataText,
                libraryName: item.libraryName,
                badges: item.badges,
                isAlertEnabled: item.isAlertEnabled == false
            )
            onStateChange?(state)
            return
        }
    }
}
