//
//  LibraryDetailViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class LibraryDetailViewController: BaseViewController {
    private let viewModel: LibraryDetailViewModel
    private weak var navigator: AppNavigator?
    private let contentView = LibraryDetailView()

    init(viewModel: LibraryDetailViewModel, navigator: AppNavigator) {
        self.viewModel = viewModel
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        Task { await viewModel.load() }
    }

    private func bind() {
        contentView.headerView.backButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapBack()
        }, for: .touchUpInside)

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func render(_ state: LibraryDetailViewModel.State) {
        guard let detail = state.detail else { return }
        contentView.nameLabel.text = detail.name
        contentView.updateContact(address: detail.address, phone: detail.phone)
        contentView.updateHours(detail.hours)
        contentView.updateHolidaySection(regular: detail.regularHolidays, upcoming: detail.upcomingHolidays)
        contentView.mapPlaceholderLabel.text = detail.mapDescription
    }
}

private final class DetailInfoRow: UIView {
    private let iconView = UIImageView()
    private let textLabel = UILabel()

    init(symbolName: String, text: String) {
        super.init(frame: .zero)

        iconView.image = UIImage(systemName: symbolName)
        iconView.tintColor = AppColor.textSecondary
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        iconView.contentMode = .scaleAspectFit
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        textLabel.font = AppTypography.caption
        textLabel.textColor = AppColor.textSecondary
        textLabel.text = text

        let stackView = UIStackView(arrangedSubviews: [iconView, textLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.s
        stackView.alignment = .center
        addSubview(stackView)
        [stackView, iconView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        stackView.pinEdges(to: self)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String) {
        textLabel.text = text
    }
}

private final class LibraryDetailView: UIView {
    let headerView = NavigationHeaderView(title: "도서관 정보", showsDivider: false)
    let nameLabel = UILabel()
    let addressLabel = UILabel()
    let phoneLabel = UILabel()
    let mapPlaceholderLabel = UILabel()

    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let infoCard = CardContainerView()
    private let hoursCard = CardContainerView()
    private let holidayCard = CardContainerView()
    private let mapCard = CardContainerView()
    private let hoursStack = UIStackView()
    private let regularHolidayStack = UIStackView()
    private let upcomingHolidayStack = UIStackView()
    private let addressRow = DetailInfoRow(symbolName: "mappin.and.ellipse", text: "")
    private let phoneRow = DetailInfoRow(symbolName: "phone.fill", text: "")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background
        accessibilityIdentifier = "libraryDetailScreen"

        [nameLabel, addressLabel, phoneLabel].forEach {
            $0.textColor = AppColor.textPrimary
        }
        nameLabel.font = AppTypography.headline
        addressLabel.font = AppTypography.caption
        phoneLabel.font = AppTypography.caption

        hoursStack.axis = .vertical
        hoursStack.spacing = AppSpacing.m
        regularHolidayStack.axis = .vertical
        regularHolidayStack.spacing = AppSpacing.s
        upcomingHolidayStack.axis = .vertical
        upcomingHolidayStack.spacing = AppSpacing.s

        mapPlaceholderLabel.textAlignment = .center
        mapPlaceholderLabel.font = AppTypography.caption
        mapPlaceholderLabel.textColor = AppColor.textSecondary
        mapPlaceholderLabel.numberOfLines = 0

        addSubviews(headerView, scrollView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.s),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: AppSpacing.l),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        setupInfoCard()
        setupHoursCard()
        setupHolidayCard()
        setupMapCard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupInfoCard() {
        infoCard.addSubviews(nameLabel, addressRow, phoneRow)
        [nameLabel, addressRow, phoneRow].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        addCard(infoCard, topAnchor: contentContainer.topAnchor)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: AppSpacing.l),
            nameLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: AppSpacing.l),
            nameLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -AppSpacing.l),

            addressRow.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: AppSpacing.m),
            addressRow.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressRow.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            phoneRow.topAnchor.constraint(equalTo: addressRow.bottomAnchor, constant: AppSpacing.s),
            phoneRow.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            phoneRow.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            phoneRow.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -AppSpacing.l)
        ])
    }

    private func setupHoursCard() {
        let titleLabel = makeCardTitle("운영 시간")
        hoursCard.addSubviews(titleLabel, hoursStack)
        [titleLabel, hoursStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        addCard(hoursCard, topAnchor: infoCard.bottomAnchor)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: hoursCard.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: hoursCard.leadingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(equalTo: hoursCard.trailingAnchor, constant: -AppSpacing.l),

            hoursStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.l),
            hoursStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            hoursStack.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            hoursStack.bottomAnchor.constraint(equalTo: hoursCard.bottomAnchor, constant: -AppSpacing.l)
        ])
    }

    private func setupHolidayCard() {
        let titleLabel = makeCardTitle("휴관일 안내")
        let regularTitle = makeSectionCaption("정기 휴관일")
        let upcomingTitle = makeSectionCaption("예정된 휴관일")

        holidayCard.addSubviews(titleLabel, regularTitle, regularHolidayStack, upcomingTitle, upcomingHolidayStack)
        [titleLabel, regularTitle, regularHolidayStack, upcomingTitle, upcomingHolidayStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        addCard(holidayCard, topAnchor: hoursCard.bottomAnchor)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: holidayCard.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: holidayCard.leadingAnchor, constant: AppSpacing.l),

            regularTitle.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.l),
            regularTitle.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            regularHolidayStack.topAnchor.constraint(equalTo: regularTitle.bottomAnchor, constant: AppSpacing.s),
            regularHolidayStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            regularHolidayStack.trailingAnchor.constraint(equalTo: holidayCard.trailingAnchor, constant: -AppSpacing.l),

            upcomingTitle.topAnchor.constraint(equalTo: regularHolidayStack.bottomAnchor, constant: AppSpacing.l),
            upcomingTitle.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            upcomingHolidayStack.topAnchor.constraint(equalTo: upcomingTitle.bottomAnchor, constant: AppSpacing.s),
            upcomingHolidayStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            upcomingHolidayStack.trailingAnchor.constraint(equalTo: holidayCard.trailingAnchor, constant: -AppSpacing.l),
            upcomingHolidayStack.bottomAnchor.constraint(equalTo: holidayCard.bottomAnchor, constant: -AppSpacing.l)
        ])
    }

    private func setupMapCard() {
        let titleLabel = makeCardTitle("위치")
        let mapPlaceholder = UIView()
        mapPlaceholder.backgroundColor = AppColor.iconSurface
        mapPlaceholder.layer.cornerRadius = AppRadius.medium
        mapPlaceholder.layer.cornerCurve = .continuous
        mapPlaceholder.layer.borderWidth = 1
        mapPlaceholder.layer.borderColor = AppColor.line.cgColor

        mapCard.addSubviews(titleLabel, mapPlaceholder, mapPlaceholderLabel)
        [titleLabel, mapPlaceholder, mapPlaceholderLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        addCard(mapCard, topAnchor: holidayCard.bottomAnchor, bottom: true)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: mapCard.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor, constant: AppSpacing.l),

            mapPlaceholder.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.l),
            mapPlaceholder.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            mapPlaceholder.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor, constant: -AppSpacing.l),
            mapPlaceholder.heightAnchor.constraint(equalToConstant: 140),
            mapPlaceholder.bottomAnchor.constraint(equalTo: mapCard.bottomAnchor, constant: -AppSpacing.l),

            mapPlaceholderLabel.centerXAnchor.constraint(equalTo: mapPlaceholder.centerXAnchor),
            mapPlaceholderLabel.centerYAnchor.constraint(equalTo: mapPlaceholder.centerYAnchor)
        ])
    }

    func updateHours(_ hours: [OperatingHour]) {
        hoursStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        hours.forEach { item in
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fill

            let dayLabel = UILabel()
            dayLabel.font = AppTypography.body
            dayLabel.textColor = AppColor.textSecondary
            dayLabel.text = item.day

            let timeLabel = UILabel()
            timeLabel.font = AppTypography.body
            timeLabel.text = item.hoursText
            timeLabel.textColor = item.isClosed ? AppColor.danger : AppColor.textPrimary

            row.addArrangedSubview(dayLabel)
            row.addArrangedSubview(UIView())
            row.addArrangedSubview(timeLabel)
            hoursStack.addArrangedSubview(row)
        }
    }

    func updateHolidaySection(regular: [HolidayEntry], upcoming: [HolidayEntry]) {
        regularHolidayStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        upcomingHolidayStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        regular.forEach { regularHolidayStack.addArrangedSubview(makePill($0.title)) }
        upcoming.forEach { upcomingHolidayStack.addArrangedSubview(makePill($0.title)) }
    }

    private func addCard(_ card: UIView, topAnchor: NSLayoutYAxisAnchor, bottom: Bool = false) {
        contentContainer.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false

        var constraints = [
            card.topAnchor.constraint(equalTo: topAnchor, constant: topAnchor === contentContainer.topAnchor ? 0 : AppSpacing.l),
            card.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: AppSpacing.xxl),
            card.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -AppSpacing.xxl)
        ]
        if bottom {
            constraints.append(card.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -AppSpacing.xxxl))
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func makeCardTitle(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = AppTypography.headline
        label.textColor = AppColor.textPrimary
        return label
    }

    private func makeSectionCaption(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = AppTypography.caption
        label.textColor = AppColor.textSecondary
        return label
    }

    private func makePill(_ title: String) -> UIView {
        let label = UILabel()
        label.text = title
        label.font = AppTypography.caption
        label.textColor = AppColor.textPrimary

        let container = UIView()
        container.backgroundColor = AppColor.chipFill
        container.layer.cornerRadius = 12
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = AppColor.line.cgColor
        container.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: AppSpacing.s),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: AppSpacing.m),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -AppSpacing.m),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -AppSpacing.s)
        ])

        return container
    }

    func updateContact(address: String, phone: String) {
        addressRow.update(text: address)
        phoneRow.update(text: phone)
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("도서관 상세") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)

    return LibraryDetailViewController(
        viewModel: LibraryDetailViewModel(
            libraryID: "library-yeoksam",
            libraryRepository: dependencies.libraryRepository
        ),
        navigator: navigator
    )
}
#endif
