//
//  HomeViewController.swift
//  Polaris
//
//  Created by 손유나 on 4/4/26.
//

import UIKit

final class HomeViewController: BaseViewController, UICollectionViewDelegate {
    private static let librariesSection = 0

    private let viewModel: HomeViewModel
    private weak var navigator: AppNavigator?
    private let contentView = HomeView()
    private lazy var dataSource = makeDataSource()

    init(viewModel: HomeViewModel, navigator: AppNavigator) {
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
        contentView.collectionView.delegate = self
        contentView.searchButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapSearch()
        }, for: .touchUpInside)
        contentView.distanceChipView.onSelectionChanged = { [weak self] distance in
            self?.viewModel.didSelectDistance(distance)
        }
        contentView.excludeToggle.onToggle = { [weak self] isOn in
            self?.viewModel.didToggleExcludeClosed(isOn)
        }
        contentView.likeButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapLikes()
        }, for: .touchUpInside)
        contentView.alertButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapAlerts()
        }, for: .touchUpInside)
        contentView.profileButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapProfile()
        }, for: .touchUpInside)

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func render(_ state: HomeViewModel.State) {
        contentView.locationLabel.text = state.locationText
        contentView.distanceChipView.updateSelection(state.selectedDistance)
        contentView.excludeToggle.isSelected = state.excludeClosed
        contentView.collectionView.backgroundView = state.libraries.isEmpty
            ? EmptyStateView(title: "주변 도서관이 없어요", message: "검색 반경이나 필터를 바꿔서 다시 찾아보세요.")
            : nil

        var snapshot = NSDiffableDataSourceSnapshot<Int, LibraryCardItemViewData>()
        snapshot.appendSections([Self.librariesSection])
        snapshot.appendItems(state.libraries, toSection: Self.librariesSection)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, LibraryCardItemViewData> {
        let registration = UICollectionView.CellRegistration<LibraryCardCell, LibraryCardItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onHeartTap = { [weak self] in
                self?.viewModel.didToggleFavorite(id: item.id)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.collectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let library = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.didSelectLibrary(id: library.id)
    }
}

private final class HomeView: UIView {
    let locationLabel = UILabel()
    let likeButton = IconActionButton(symbolName: "heart", accessibilityLabel: "찜 화면 열기")
    let alertButton = IconActionButton(symbolName: "bell", accessibilityLabel: "알림 화면 열기")
    let profileButton = IconActionButton(symbolName: "person.crop.circle", accessibilityLabel: "프로필 화면 열기")
    let searchButton = SearchTriggerButton(placeholder: "도서명, 저자, 출판사 검색")
    let distanceChipView = FilterChipGroupView(options: DistanceOption.allCases, selected: .oneKm)
    let excludeToggle = InlineToggleView(title: "운영종료 제외")
    let collectionView: UICollectionView

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: HomeView.makeLayout())
        super.init(frame: frame)
        backgroundColor = AppColor.background

        locationLabel.font = AppTypography.body
        locationLabel.textColor = AppColor.textPrimary

        let actionStack = UIStackView(arrangedSubviews: [likeButton, alertButton, profileButton])
        actionStack.axis = .horizontal
        actionStack.spacing = AppSpacing.s
        actionStack.alignment = .center

        let distanceHeader = SectionHeaderView(title: "검색 반경")
        let libraryHeader = SectionHeaderView(title: "주변 도서관", accessoryView: excludeToggle)

        collectionView.backgroundColor = .clear

        addSubviews(locationLabel, actionStack, searchButton, distanceHeader, distanceChipView, libraryHeader, collectionView)
        [locationLabel, actionStack, searchButton, distanceHeader, distanceChipView, libraryHeader, collectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            locationLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.xxl),
            locationLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),

            actionStack.centerYAnchor.constraint(equalTo: locationLabel.centerYAnchor),
            actionStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            searchButton.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: AppSpacing.l),
            searchButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            searchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),
            searchButton.heightAnchor.constraint(equalToConstant: 48),

            distanceHeader.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: AppSpacing.xxxl),
            distanceHeader.leadingAnchor.constraint(equalTo: searchButton.leadingAnchor),
            distanceHeader.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),

            distanceChipView.topAnchor.constraint(equalTo: distanceHeader.bottomAnchor, constant: AppSpacing.l),
            distanceChipView.leadingAnchor.constraint(equalTo: searchButton.leadingAnchor),
            distanceChipView.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),
            distanceChipView.heightAnchor.constraint(equalToConstant: 48),

            libraryHeader.topAnchor.constraint(equalTo: distanceChipView.bottomAnchor, constant: AppSpacing.xxxl),
            libraryHeader.leadingAnchor.constraint(equalTo: searchButton.leadingAnchor),
            libraryHeader.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: libraryHeader.bottomAnchor, constant: AppSpacing.l),
            collectionView.leadingAnchor.constraint(equalTo: searchButton.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        accessibilityIdentifier = "homeScreen"
        searchButton.accessibilityIdentifier = "home.searchInput"
        likeButton.accessibilityIdentifier = "home.likesButton"
        alertButton.accessibilityIdentifier = "home.alertsButton"
        profileButton.accessibilityIdentifier = "home.profileButton"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(108)
            ))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(108)
            ), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = AppSpacing.m
            section.contentInsets = .init(top: 0, leading: 0, bottom: AppSpacing.xxl, trailing: 0)
            return section
        }
    }
}
