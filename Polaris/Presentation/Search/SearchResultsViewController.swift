//
//  SearchResultsViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

final class SearchResultsViewController: BaseViewController, UICollectionViewDelegate {
    private static let booksSection = 0
    private static let librariesSection = 0

    private let viewModel: SearchResultsViewModel
    private weak var navigator: AppNavigator?
    private let contentView = SearchResultsView()

    private lazy var booksDataSource = makeBooksDataSource()
    private lazy var librariesDataSource = makeLibrariesDataSource()

    init(viewModel: SearchResultsViewModel, navigator: AppNavigator) {
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
        contentView.booksCollectionView.delegate = self
        contentView.librariesCollectionView.delegate = self

        contentView.backButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapBack()
        }, for: .touchUpInside)

        contentView.searchInputView.isEditable = true
        contentView.searchInputView.onSubmit = { [weak self] query in
            self?.viewModel.didSubmitQuery(query)
        }
        contentView.excludeToggle.onToggle = { [weak self] isOn in
            self?.viewModel.didToggleExcludeUnavailable(isOn)
        }

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func render(_ state: SearchResultsViewModel.State) {
        contentView.searchInputView.text = state.query.text
        contentView.excludeToggle.isSelected = state.query.excludeUnavailable
        contentView.booksCollectionView.backgroundView = state.books.isEmpty
            ? EmptyStateView(title: "도서를 찾지 못했어요", message: "도서명이나 저자를 조금 다르게 입력해보세요.")
            : nil
        contentView.librariesCollectionView.backgroundView = state.libraries.isEmpty
            ? EmptyStateView(title: "도서관 결과가 없어요", message: "검색어나 대출 가능 필터를 조정해보세요.")
            : nil

        var bookSnapshot = NSDiffableDataSourceSnapshot<Int, BookCarouselItemViewData>()
        bookSnapshot.appendSections([Self.booksSection])
        bookSnapshot.appendItems(state.books, toSection: Self.booksSection)
        booksDataSource.apply(bookSnapshot, animatingDifferences: false)

        var librarySnapshot = NSDiffableDataSourceSnapshot<Int, LibraryCardItemViewData>()
        librarySnapshot.appendSections([Self.librariesSection])
        librarySnapshot.appendItems(state.libraries, toSection: Self.librariesSection)
        librariesDataSource.apply(librarySnapshot, animatingDifferences: false)
    }

    private func makeBooksDataSource() -> UICollectionViewDiffableDataSource<Int, BookCarouselItemViewData> {
        let registration = UICollectionView.CellRegistration<BookCarouselCell, BookCarouselItemViewData> { cell, _, item in
            cell.configure(viewData: item)
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.booksCollectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
    }

    private func makeLibrariesDataSource() -> UICollectionViewDiffableDataSource<Int, LibraryCardItemViewData> {
        let registration = UICollectionView.CellRegistration<LibraryCardCell, LibraryCardItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onBellTap = { [weak self] in
                self?.viewModel.didToggleLibraryAlert(id: item.id)
            }
            cell.onHeartTap = { [weak self] in
                self?.viewModel.didToggleLibraryFavorite(id: item.id)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.librariesCollectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == contentView.booksCollectionView,
           let book = booksDataSource.itemIdentifier(for: indexPath) {
            viewModel.didSelectBook(id: book.id)
        } else if collectionView == contentView.librariesCollectionView,
                  let library = librariesDataSource.itemIdentifier(for: indexPath) {
            viewModel.didSelectLibrary(id: library.id)
        }
    }
}

private final class SearchResultsView: UIView {
    let backButton = IconActionButton(symbolName: "arrow.left", accessibilityLabel: "뒤로가기")
    let searchInputView = SearchInputView(placeholder: "도서명, 저자, 출판사 검색")
    let booksCollectionView: UICollectionView
    let librariesCollectionView: UICollectionView
    let excludeToggle = InlineToggleView(title: "대출불가 제외")

    override init(frame: CGRect) {
        booksCollectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchResultsView.makeBooksLayout())
        librariesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchResultsView.makeLibrariesLayout())
        super.init(frame: frame)

        backgroundColor = AppColor.background
        booksCollectionView.backgroundColor = .clear
        librariesCollectionView.backgroundColor = .clear

        let searchHeaderStack = UIStackView(arrangedSubviews: [backButton, searchInputView])
        searchHeaderStack.axis = .horizontal
        searchHeaderStack.spacing = AppSpacing.l
        searchHeaderStack.alignment = .center

        let libraryHeader = SectionHeaderView(title: "주변 도서관", accessoryView: excludeToggle)

        addSubviews(searchHeaderStack, booksCollectionView, libraryHeader, librariesCollectionView)
        [searchHeaderStack, booksCollectionView, libraryHeader, librariesCollectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            searchHeaderStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.xxl),
            searchHeaderStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            searchHeaderStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            booksCollectionView.topAnchor.constraint(equalTo: searchHeaderStack.bottomAnchor, constant: AppSpacing.xxl),
            booksCollectionView.leadingAnchor.constraint(equalTo: searchHeaderStack.leadingAnchor),
            booksCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            booksCollectionView.heightAnchor.constraint(equalToConstant: 220),

            libraryHeader.topAnchor.constraint(equalTo: booksCollectionView.bottomAnchor, constant: AppSpacing.xxxl),
            libraryHeader.leadingAnchor.constraint(equalTo: searchHeaderStack.leadingAnchor),
            libraryHeader.trailingAnchor.constraint(equalTo: searchHeaderStack.trailingAnchor),

            librariesCollectionView.topAnchor.constraint(equalTo: libraryHeader.bottomAnchor, constant: AppSpacing.l),
            librariesCollectionView.leadingAnchor.constraint(equalTo: searchHeaderStack.leadingAnchor),
            librariesCollectionView.trailingAnchor.constraint(equalTo: searchHeaderStack.trailingAnchor),
            librariesCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        accessibilityIdentifier = "searchScreen"
        backButton.accessibilityIdentifier = "search.backButton"
        librariesCollectionView.accessibilityIdentifier = "search.libraryCollection"
        booksCollectionView.accessibilityIdentifier = "search.bookCollection"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeBooksLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .absolute(132),
                heightDimension: .absolute(204)
            ))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                widthDimension: .absolute(132),
                heightDimension: .absolute(204)
            ), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            section.interGroupSpacing = AppSpacing.m
            section.contentInsets = .init(top: 0, leading: AppSpacing.xxl, bottom: 0, trailing: AppSpacing.xxl)
            return section
        }
    }

    private static func makeLibrariesLayout() -> UICollectionViewLayout {
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
