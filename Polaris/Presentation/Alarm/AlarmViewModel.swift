import Foundation

@MainActor
final class AlarmViewModel {
    struct State: Equatable {
        var sections: [AlertSection: [AlertBookItemViewData]] = [:]
        var errorMessage: String?
    }

    var onStateChange: ((State) -> Void)?
    var onRoute: ((AppRoute) -> Void)?

    private let alertsRepository: any AlertsRepository
    private(set) var state = State()

    init(alertsRepository: any AlertsRepository) {
        self.alertsRepository = alertsRepository
    }

    func load() async {
        do {
            async let alerts = alertsRepository.fetchAlerts()
            async let subscriptions = alertsRepository.fetchAlertSubscriptions()

            let fetchedAlerts = try await alerts
            let fetchedSubscriptions = try await subscriptions
            let availableItems = fetchedAlerts.map(makeAvailableAlertViewData)
            let subscriptionItems = fetchedSubscriptions.map(makeSubscriptionViewData)
            var sections: [AlertSection: [AlertBookItemViewData]] = [:]
            if availableItems.isEmpty == false {
                sections[.available] = availableItems
            }
            if subscriptionItems.isEmpty == false {
                sections[.waiting] = subscriptionItems
            }
            state.sections = sections
            state.errorMessage = nil
        } catch {
            state.sections = [:]
            state.errorMessage = "알림 목록을 불러오지 못했습니다."
        }
        onStateChange?(state)
    }

    func didTapBack() {
        onRoute?(.back)
    }

    func didSelectBook(id: String) {
        onRoute?(.bookDetail(id: id))
    }

    func didDeleteAlert(id: String) async {
        await didTapAction(id: id)
    }

    func didTapAction(id: String) async {
        for section in AlertSection.allCases {
            guard let item = state.sections[section]?.first(where: { $0.id == id }) else { continue }
            let previousSections = state.sections
            removeItem(id: id, from: section)
            state.errorMessage = nil
            onStateChange?(state)

            do {
                switch item.action {
                case .delete:
                    try await alertsRepository.deleteAlert(id: item.id)
                case .unsubscribe:
                    try await alertsRepository.setAlertSubscription(
                        bookID: item.bookID,
                        libraryID: item.libraryID,
                        isEnabled: false
                    )
                }
            } catch {
                state.sections = previousSections
                state.errorMessage = item.action == .delete ? "알림을 삭제하지 못했습니다." : "알림 신청을 해제하지 못했습니다."
                onStateChange?(state)
            }
            return
        }
    }

    private func removeItem(id: String, from section: AlertSection) {
        state.sections[section]?.removeAll { $0.id == id }
        if state.sections[section]?.isEmpty == true {
            state.sections[section] = nil
        }
    }

    private func makeAvailableAlertViewData(_ item: AlertItem) -> AlertBookItemViewData {
        AlertBookItemViewData(
            id: item.id,
            bookID: item.book.id,
            libraryID: item.libraryID,
            title: item.book.title,
            metadataText: "\(item.libraryName)에서 대출가능 상태로 바뀌었습니다.",
            coverImageURL: item.book.coverImageURL,
            libraryName: item.libraryName,
            messageText: "",
            badges: [makeLoanBadge(.available)],
            isAlertEnabled: item.book.isAlertEnabled,
            action: .delete
        )
    }

    private func makeSubscriptionViewData(_ item: AlertItem) -> AlertBookItemViewData {
        AlertBookItemViewData(
            id: item.id,
            bookID: item.book.id,
            libraryID: item.libraryID,
            title: item.book.title,
            metadataText: "\(item.libraryName)에서 알림 신청 중입니다.",
            coverImageURL: item.book.coverImageURL,
            libraryName: item.libraryName,
            messageText: "대출가능 상태가 되면 알림으로 알려드릴게요.",
            badges: [BadgeContent(title: "알림 신청중", tone: .blue)],
            isAlertEnabled: true,
            action: .unsubscribe
        )
    }
}
