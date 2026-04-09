//
//  LibraryDetailViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import MapKit
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
        contentView.render(detail)
    }
}

private final class DetailInfoRow: UIView {
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(symbolName: String, title: String) {
        super.init(frame: .zero)

        iconContainer.backgroundColor = AppColor.iconSurface
        iconContainer.layer.cornerRadius = 17
        iconContainer.layer.cornerCurve = .continuous

        iconView.image = UIImage(systemName: symbolName)
        iconView.tintColor = AppColor.accent
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = AppTypography.tiny
        titleLabel.textColor = AppColor.textTertiary
        titleLabel.text = title

        valueLabel.font = AppTypography.body
        valueLabel.textColor = AppColor.textPrimary
        valueLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        textStack.axis = .vertical
        textStack.spacing = 3

        let stackView = UIStackView(arrangedSubviews: [iconContainer, textStack])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.m
        stackView.alignment = .top

        iconContainer.addSubview(iconView)
        addSubview(stackView)
        [stackView, iconContainer, iconView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        stackView.pinEdges(to: self)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 34),
            iconContainer.heightAnchor.constraint(equalToConstant: 34),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(text: String) {
        valueLabel.text = text
    }
}

private final class LibraryDetailView: UIView {
    let headerView = NavigationHeaderView(title: "도서관 정보", showsDivider: false)
    let nameLabel = UILabel()

    private let scrollView = UIScrollView()
    private let contentContainer = UIView()
    private let infoCard = CardContainerView()
    private let mapCard = CardContainerView()
    private let mapView = MKMapView()
    private let mapFallbackLabel = UILabel()
    private let hoursStack = UIStackView()
    private let holidayStack = UIStackView()
    private let regularHolidayStack = UIStackView()
    private let upcomingHolidayStack = UIStackView()
    private let addressRow = DetailInfoRow(symbolName: "mappin.and.ellipse", title: "주소")
    private let phoneRow = DetailInfoRow(symbolName: "phone.fill", title: "전화")

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background
        accessibilityIdentifier = "libraryDetailScreen"

        nameLabel.font = AppTypography.hero
        nameLabel.textColor = AppColor.textPrimary
        nameLabel.numberOfLines = 2

        hoursStack.axis = .vertical
        hoursStack.spacing = AppSpacing.m
        holidayStack.axis = .vertical
        holidayStack.spacing = AppSpacing.m
        regularHolidayStack.axis = .vertical
        regularHolidayStack.spacing = AppSpacing.s
        upcomingHolidayStack.axis = .vertical
        upcomingHolidayStack.spacing = AppSpacing.s

        mapView.layer.cornerRadius = AppRadius.medium
        mapView.layer.cornerCurve = .continuous
        mapView.clipsToBounds = true
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false

        mapFallbackLabel.textAlignment = .center
        mapFallbackLabel.font = AppTypography.caption
        mapFallbackLabel.textColor = AppColor.textSecondary
        mapFallbackLabel.numberOfLines = 0
        mapFallbackLabel.isHidden = true

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
        setupMapCard()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupInfoCard() {
        let hoursTitle = makeCardTitle("운영 시간")
        let holidayTitle = makeCardTitle("휴관일 안내")
        holidayStack.addArrangedSubview(makeHolidayGroup(title: "정기", contentStack: regularHolidayStack))
        holidayStack.addArrangedSubview(makeHolidayGroup(title: "예정", contentStack: upcomingHolidayStack))

        infoCard.addSubviews(
            nameLabel,
            addressRow,
            phoneRow,
            hoursTitle,
            hoursStack,
            holidayTitle,
            holidayStack
        )
        [
            nameLabel,
            addressRow,
            phoneRow,
            hoursTitle,
            hoursStack,
            holidayTitle,
            holidayStack
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        addCard(infoCard, topAnchor: contentContainer.topAnchor)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: AppSpacing.xxl),
            nameLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: AppSpacing.xxl),
            nameLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -AppSpacing.xxl),

            addressRow.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: AppSpacing.xl),
            addressRow.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressRow.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            phoneRow.topAnchor.constraint(equalTo: addressRow.bottomAnchor, constant: AppSpacing.l),
            phoneRow.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            phoneRow.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            hoursTitle.topAnchor.constraint(equalTo: phoneRow.bottomAnchor, constant: AppSpacing.xxl),
            hoursTitle.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            hoursTitle.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            hoursStack.topAnchor.constraint(equalTo: hoursTitle.bottomAnchor, constant: AppSpacing.m),
            hoursStack.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            hoursStack.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            holidayTitle.topAnchor.constraint(equalTo: hoursStack.bottomAnchor, constant: AppSpacing.xxxl + AppSpacing.m),
            holidayTitle.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            holidayTitle.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            holidayStack.topAnchor.constraint(equalTo: holidayTitle.bottomAnchor, constant: AppSpacing.l),
            holidayStack.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            holidayStack.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            holidayStack.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -AppSpacing.xxl)
        ])
    }

    private func setupMapCard() {
        let titleLabel = makeCardTitle("위치")
        mapCard.addSubviews(titleLabel, mapView, mapFallbackLabel)
        [titleLabel, mapView, mapFallbackLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        addCard(mapCard, topAnchor: infoCard.bottomAnchor, bottom: true)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: mapCard.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: mapCard.leadingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(equalTo: mapCard.trailingAnchor, constant: -AppSpacing.l),

            mapView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.l),
            mapView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            mapView.heightAnchor.constraint(equalToConstant: 190),
            mapView.bottomAnchor.constraint(equalTo: mapCard.bottomAnchor, constant: -AppSpacing.l),

            mapFallbackLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            mapFallbackLabel.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            mapFallbackLabel.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: AppSpacing.l),
            mapFallbackLabel.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -AppSpacing.l)
        ])
    }

    func render(_ detail: LibraryDetail) {
        nameLabel.text = detail.name
        updateContact(address: detail.address, phone: detail.phone)
        updateHours(detail.hours)
        updateHolidaySection(regular: detail.regularHolidays, upcoming: detail.upcomingHolidays)
        updateMap(detail)
    }

    private func updateHours(_ hours: [OperatingHour]) {
        hoursStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        hours.forEach { item in
            let row = UIStackView()
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = AppSpacing.m

            let dayLabel = UILabel()
            dayLabel.font = AppTypography.subheadline
            dayLabel.textColor = AppColor.textSecondary
            dayLabel.text = item.day

            let timeLabel = UILabel()
            timeLabel.font = AppTypography.subheadline
            timeLabel.textAlignment = .right
            timeLabel.text = prettyHoursText(item.hoursText)
            timeLabel.textColor = item.isClosed ? AppColor.danger : AppColor.textPrimary
            timeLabel.numberOfLines = 1
            timeLabel.adjustsFontSizeToFitWidth = true
            timeLabel.minimumScaleFactor = 0.85

            row.addArrangedSubview(dayLabel)
            row.addArrangedSubview(UIView())
            row.addArrangedSubview(timeLabel)
            hoursStack.addArrangedSubview(row)
        }
    }

    private func updateHolidaySection(regular: [HolidayEntry], upcoming: [HolidayEntry]) {
        regularHolidayStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        upcomingHolidayStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if regular.isEmpty {
            regularHolidayStack.addArrangedSubview(makePlainHolidayLabel("정보 없음"))
        } else {
            regular.forEach { regularHolidayStack.addArrangedSubview(makePlainHolidayLabel($0.title)) }
        }

        if upcoming.isEmpty {
            upcomingHolidayStack.addArrangedSubview(makePlainHolidayLabel("예정된 휴관일이 없어요"))
        } else {
            upcoming.forEach { upcomingHolidayStack.addArrangedSubview(makePlainHolidayLabel($0.title)) }
        }
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

    private func makeHolidayGroup(title: String, contentStack: UIStackView) -> UIView {
        let titleLabel = makeSectionCaption(title)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [titleLabel, contentStack])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = AppSpacing.l

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.widthAnchor.constraint(equalToConstant: 44)
        ])

        return row
    }

    private func makePlainHolidayLabel(_ title: String) -> UILabel {
        let label = UILabel()
        label.text = title
        label.font = AppTypography.caption
        label.textColor = AppColor.textSecondary
        label.numberOfLines = 0
        return label
    }

    private func updateContact(address: String, phone: String) {
        addressRow.update(text: address)
        phoneRow.update(text: phone)
    }

    private func updateMap(_ detail: LibraryDetail) {
        mapView.removeAnnotations(mapView.annotations)
        guard let latitude = detail.latitude, let longitude = detail.longitude else {
            mapView.isHidden = true
            mapFallbackLabel.isHidden = false
            mapFallbackLabel.text = detail.mapDescription
            return
        }

        mapView.isHidden = false
        mapFallbackLabel.isHidden = true

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 650,
            longitudinalMeters: 650
        )
        mapView.setRegion(region, animated: false)

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = detail.name
        annotation.subtitle = detail.address
        mapView.addAnnotation(annotation)
    }
}

private func prettyHoursText(_ rawText: String) -> String {
    let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedText.contains(":") else { return trimmedText }

    let separators = [" - ", " ~ ", "~", "-"]
    guard let separator = separators.first(where: { trimmedText.contains($0) }) else {
        return prettyClockText(trimmedText)
    }

    let parts = trimmedText.components(separatedBy: separator)
    guard parts.count == 2 else { return trimmedText }
    return "\(prettyClockText(parts[0])) ~ \(prettyClockText(parts[1]))"
}

private func prettyClockText(_ rawText: String) -> String {
    let trimmedText = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    let parts = trimmedText.split(separator: ":").compactMap { Int($0) }
    guard let hour24 = parts.first else { return trimmedText }

    let minute = parts.count > 1 ? parts[1] : 0
    let period = hour24 < 12 ? "오전" : "오후"
    let hour12 = {
        let value = hour24 % 12
        return value == 0 ? 12 : value
    }()

    if minute == 0 {
        return "\(period) \(hour12)시"
    }
    return "\(period) \(hour12)시 \(minute)분"
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
