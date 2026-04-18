//
//  LikeViewController.swift
//  Polaris
//
//  Created by 손유나 on 4/1/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

private enum LikeItem: Hashable, Sendable {
    case book(FavoriteBookItemViewData)
    case library(LibraryCardItemViewData)
}

final class LikeViewController: BaseViewController, UICollectionViewDelegate {
    private static let mainSection = 0

    private let viewModel: LikeViewModel
    private weak var navigator: AppNavigator?
    private let contentView = LikeView()
    private lazy var dataSource = makeDataSource()

    init(viewModel: LikeViewModel, navigator: AppNavigator) {
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
        contentView.headerView.backButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapBack()
        }, for: .touchUpInside)
        contentView.segmentControl.onSelectionChanged = { [weak self] index in
            self?.viewModel.didSelectTab(index: index)
        }

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func render(_ state: LikeViewModel.State) {
        contentView.segmentControl.updateTitles([
            "도서 (\(state.books.count))",
            "도서관 (\(state.libraries.count))"
        ])
        contentView.segmentControl.setSelectedIndex(state.selectedTab.rawValue, animated: false)

        let items: [LikeItem]
        switch state.selectedTab {
        case .books:
            items = state.books.map(LikeItem.book)
            contentView.collectionView.backgroundView = state.books.isEmpty
                ? EmptyStateView(title: "찜 API 미구현", message: "도서 찜 API가 아직 제공되지 않았습니다.")
                : nil
        case .libraries:
            items = state.libraries.map(LikeItem.library)
            contentView.collectionView.backgroundView = state.libraries.isEmpty
                ? EmptyStateView(title: "찜 API 미구현", message: "도서관 찜 API가 아직 제공되지 않았습니다.")
                : nil
        }

        var snapshot = NSDiffableDataSourceSnapshot<Int, LikeItem>()
        snapshot.appendSections([Self.mainSection])
        snapshot.appendItems(items, toSection: Self.mainSection)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<Int, LikeItem> {
        let favoriteRegistration = UICollectionView.CellRegistration<FavoriteBookCell, FavoriteBookItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onBellTap = { [weak self] in
                self?.viewModel.didToggleBookAlert(id: item.id)
            }
            cell.onHeartTap = { [weak self] in
                self?.viewModel.didToggleBookFavorite(id: item.id)
            }
        }

        let libraryRegistration = UICollectionView.CellRegistration<LibraryCardCell, LibraryCardItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onHeartTap = { [weak self] in
                self?.viewModel.didToggleLibraryFavorite(id: item.id)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.collectionView) { collectionView, indexPath, item in
            switch item {
            case let .book(book):
                return collectionView.dequeueConfiguredReusableCell(using: favoriteRegistration, for: indexPath, item: book)
            case let .library(library):
                return collectionView.dequeueConfiguredReusableCell(using: libraryRegistration, for: indexPath, item: library)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        switch item {
        case let .book(book):
            viewModel.didSelectBook(id: book.id)
        case let .library(library):
            viewModel.didSelectLibrary(id: library.id)
        }
    }
}

private final class LikeView: UIView {
    let headerView = NavigationHeaderView(title: "찜", showsDivider: false)
    let segmentControl = UnderlineSegmentControlView(titles: ["도서 (0)", "도서관 (0)"])
    let dividerView = UIView()
    let collectionView: UICollectionView

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: LikeView.makeLayout())
        super.init(frame: frame)

        backgroundColor = AppColor.background
        dividerView.backgroundColor = AppColor.line
        collectionView.backgroundColor = .clear

        addSubviews(headerView, segmentControl, dividerView, collectionView)
        [headerView, segmentControl, dividerView, collectionView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.s),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            segmentControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: AppSpacing.m),
            segmentControl.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            segmentControl.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            segmentControl.heightAnchor.constraint(equalToConstant: 40),

            dividerView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor),
            dividerView.leadingAnchor.constraint(equalTo: segmentControl.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: segmentControl.trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            collectionView.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: AppSpacing.m),
            collectionView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        accessibilityIdentifier = "likesScreen"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(96)
            ))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .estimated(96)
            ), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = AppSpacing.s
            section.contentInsets = .init(top: 0, leading: 0, bottom: AppSpacing.xxl, trailing: 0)
            return section
        }
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("찜") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)

    return LikeViewController(
        viewModel: LikeViewModel(favoritesRepository: dependencies.favoritesRepository),
        navigator: navigator
    )
}
#endif
