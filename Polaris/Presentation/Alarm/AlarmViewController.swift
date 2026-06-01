//
//  AlarmViewController.swift
//  Polaris
//
//  Created by 손유나 on 4/1/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class AlarmViewController: BaseViewController, UICollectionViewDelegate {
    private let viewModel: AlarmViewModel
    private weak var navigator: AppNavigator?
    private let contentView = AlarmRootView()
    private lazy var dataSource = makeDataSource()

    init(viewModel: AlarmViewModel, navigator: AppNavigator) {
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

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func render(_ state: AlarmViewModel.State) {
        contentView.collectionView.backgroundView = state.sections.isEmpty
            ? EmptyStateView(
                title: state.errorMessage == nil ? "받은 알림이 없어요" : "알림을 불러오지 못했어요",
                message: state.errorMessage ?? "대출 가능으로 바뀐 도서가 있으면 이곳에서 확인할 수 있어요."
            )
            : nil
        var snapshot = NSDiffableDataSourceSnapshot<AlertSection, AlertBookItemViewData>()
        AlertSection.allCases.forEach { section in
            let items = state.sections[section] ?? []
            guard items.isEmpty == false else { return }
            snapshot.appendSections([section])
            snapshot.appendItems(items, toSection: section)
        }
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<AlertSection, AlertBookItemViewData> {
        let registration = UICollectionView.CellRegistration<AlertBookCell, AlertBookItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onActionTap = { [weak self] in
                Task { await self?.viewModel.didTapAction(id: item.id) }
            }
        }

        let dataSource = UICollectionViewDiffableDataSource<AlertSection, AlertBookItemViewData>(collectionView: contentView.collectionView) { collectionView, indexPath, item in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: item)
        }

        let supplementaryRegistration = UICollectionView.SupplementaryRegistration<CollectionSectionHeaderView>(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak dataSource] headerView, _, indexPath in
            guard let section = dataSource?.snapshot().sectionIdentifiers[indexPath.section] else { return }
            headerView.titleLabel.text = section.title
        }

        dataSource.supplementaryViewProvider = { collectionView, kind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: supplementaryRegistration, for: indexPath)
        }

        return dataSource
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.didSelectBook(id: item.bookID)
    }
}

private final class AlarmRootView: UIView {
    let headerView = NavigationHeaderView(title: "알림")
    let collectionView: UICollectionView

    override init(frame: CGRect) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: AlarmRootView.makeLayout())
        super.init(frame: frame)

        backgroundColor = AppColor.background
        collectionView.backgroundColor = .clear

        addSubviews(headerView, collectionView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.s),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: AppSpacing.xl),
            collectionView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        accessibilityIdentifier = "alertsScreen"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(AlertBookCell.preferredHeight)
            ))
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(AlertBookCell.preferredHeight)
            ), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = AppSpacing.m
            section.contentInsets = .init(top: AppSpacing.xs, leading: 0, bottom: AppSpacing.xxxl, trailing: 0)
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(24)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            section.boundarySupplementaryItems = [header]
            return section
        }
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("알림") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)

    return AlarmViewController(
        viewModel: AlarmViewModel(alertsRepository: dependencies.alertsRepository),
        navigator: navigator
    )
}
#endif
