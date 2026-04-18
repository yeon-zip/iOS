//
//  SearchResultsViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class SearchResultsViewController: BaseViewController, UICollectionViewDelegate {
    private static let booksSection = 0
    private static let librariesSection = 0

    private let viewModel: SearchResultsViewModel
    private weak var navigator: AppNavigator?
    private let contentView = SearchResultsView()

    private lazy var booksDataSource = makeBooksDataSource()
    private lazy var librariesDataSource = makeLibrariesDataSource()
    private var backPanStartPoints: [ObjectIdentifier: CGPoint] = [:]

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
        contentView.observeBackPans(target: self, action: #selector(handleBackPan(_:)))
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
        contentView.distanceChipView.onSelectionChanged = { [weak self] distance in
            self?.viewModel.didSelectDistance(distance)
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
        contentView.distanceChipView.updateSelection(state.selectedDistance)
        contentView.excludeToggle.isSelected = state.query.excludeUnavailable
        contentView.updateExcludeToggleEnabled(state.selectedBookID != nil)
        contentView.setBooksLoading(state.isBooksLoading)
        contentView.setLibrariesLoading(state.isLibrariesLoading)
        contentView.updateLibraryHeaderTitle(
            state.selectedBookID == nil ? "주변 도서관" : "주변 보유 도서관"
        )
        if state.isBooksLoading {
            contentView.booksCollectionView.backgroundView = nil
        } else if state.books.isEmpty {
            contentView.booksCollectionView.backgroundView = state.query.text.isEmpty
                ? EmptyStateView(title: "도서를 검색해보세요", message: "도서명, 저자, 출판사로 검색할 수 있어요.")
                : EmptyStateView(title: "도서를 찾지 못했어요", message: "도서명이나 저자를 조금 다르게 입력해보세요.")
        } else {
            contentView.booksCollectionView.backgroundView = nil
        }
        contentView.librariesCollectionView.backgroundView = state.isLibrariesLoading
            ? nil
            : state.libraries.isEmpty
                ? EmptyStateView(
                    title: state.selectedBookID == nil ? "주변 도서관이 없어요" : "보유 도서관이 없어요",
                    message: state.selectedBookID == nil
                        ? "현재 위치 기준 반경 안에서 찾지 못했어요."
                        : "다른 책을 선택하거나 대출 가능 필터를 조정해보세요."
                )
                : nil

        var bookSnapshot = NSDiffableDataSourceSnapshot<Int, BookCarouselItemViewData>()
        bookSnapshot.appendSections([Self.booksSection])
        bookSnapshot.appendItems(state.books, toSection: Self.booksSection)
        booksDataSource.apply(bookSnapshot, animatingDifferences: false)

        var librarySnapshot = NSDiffableDataSourceSnapshot<Int, LibraryCardItemViewData>()
        librarySnapshot.appendSections([Self.librariesSection])
        librarySnapshot.appendItems(state.libraries, toSection: Self.librariesSection)
        librariesDataSource.apply(librarySnapshot, animatingDifferences: false)
        contentView.updateLibraryMinimumHeight(isEmpty: state.libraries.isEmpty || state.isLibrariesLoading)
    }

    private func makeBooksDataSource() -> UICollectionViewDiffableDataSource<Int, BookCarouselItemViewData> {
        let registration = UICollectionView.CellRegistration<BookCarouselCell, BookCarouselItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onDetailTap = { [weak self] in
                self?.viewModel.didTapBookDetail(id: item.id)
            }
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
            _ = viewModel.didSelectBook(id: book.id)
        } else if collectionView == contentView.librariesCollectionView,
                  let library = librariesDataSource.itemIdentifier(for: indexPath) {
            viewModel.didSelectLibrary(id: library.id)
        }
    }

    @objc private func handleBackPan(_ recognizer: UIPanGestureRecognizer) {
        let key = ObjectIdentifier(recognizer)

        switch recognizer.state {
        case .began:
            backPanStartPoints[key] = recognizer.location(in: view)
        case .ended:
            let startPoint = backPanStartPoints.removeValue(forKey: key)
            let translation = recognizer.translation(in: view)
            let velocity = recognizer.velocity(in: view)
            guard let startPoint else { return }
            guard startPoint.x <= 24 else { return }
            guard translation.x > 80, velocity.x > 0 else { return }
            guard abs(translation.x) > abs(translation.y) else { return }
            viewModel.didTapBack()
        case .cancelled, .failed:
            backPanStartPoints.removeValue(forKey: key)
        default:
            break
        }
    }
}

private final class SearchResultsView: UIView {
    let backButton = IconActionButton(symbolName: "chevron.left", accessibilityLabel: "뒤로가기")
    let searchInputView = SearchInputView(placeholder: "도서명, 저자, 출판사 검색")
    let booksCollectionView: UICollectionView
    let librariesCollectionView: ContentSizedCollectionView
    let distanceChipView = FilterChipGroupView(options: DistanceOption.allCases, selected: .twoKm)
    let excludeToggle = InlineToggleView(title: "대출불가 제외")
    private let booksLoadingView = LoadingOverlayView()
    private let librariesLoadingView = LoadingOverlayView()
    private let distanceHeader = SectionHeaderView(title: "검색 반경")
    private let libraryHeader: SectionHeaderView
    private let backCaptureView = UIView()
    private let scrollView = UIScrollView()
    private let scrollContentView = UIView()

    override init(frame: CGRect) {
        booksCollectionView = UICollectionView(frame: .zero, collectionViewLayout: SearchResultsView.makeBooksLayout())
        librariesCollectionView = ContentSizedCollectionView(frame: .zero, collectionViewLayout: SearchResultsView.makeLibrariesLayout())
        libraryHeader = SectionHeaderView(title: "주변 도서관", accessoryView: excludeToggle)
        super.init(frame: frame)

        backgroundColor = AppColor.background
        booksCollectionView.backgroundColor = .clear
        librariesCollectionView.backgroundColor = .clear
        librariesCollectionView.isScrollEnabled = false
        backCaptureView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true

        let searchHeaderStack = UIStackView(arrangedSubviews: [backButton, searchInputView])
        searchHeaderStack.axis = .horizontal
        searchHeaderStack.spacing = AppSpacing.l
        searchHeaderStack.alignment = .center

        addSubviews(searchHeaderStack, scrollView, backCaptureView)
        [searchHeaderStack, scrollView, backCaptureView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        scrollView.addSubview(scrollContentView)
        scrollContentView.translatesAutoresizingMaskIntoConstraints = false
        scrollContentView.addSubviews(
            booksCollectionView,
            booksLoadingView,
            distanceHeader,
            distanceChipView,
            libraryHeader,
            librariesCollectionView,
            librariesLoadingView
        )
        [booksCollectionView, booksLoadingView, distanceHeader, distanceChipView, libraryHeader, librariesCollectionView, librariesLoadingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            searchHeaderStack.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.s),
            searchHeaderStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            searchHeaderStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            scrollView.topAnchor.constraint(equalTo: searchHeaderStack.bottomAnchor, constant: AppSpacing.xl),
            scrollView.leadingAnchor.constraint(equalTo: searchHeaderStack.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: searchHeaderStack.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            backCaptureView.topAnchor.constraint(equalTo: topAnchor),
            backCaptureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backCaptureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backCaptureView.widthAnchor.constraint(equalToConstant: 24),

            scrollContentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            booksCollectionView.topAnchor.constraint(equalTo: scrollContentView.topAnchor),
            booksCollectionView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            booksCollectionView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            booksCollectionView.heightAnchor.constraint(equalToConstant: 220),

            booksLoadingView.topAnchor.constraint(equalTo: booksCollectionView.topAnchor),
            booksLoadingView.leadingAnchor.constraint(equalTo: booksCollectionView.leadingAnchor),
            booksLoadingView.trailingAnchor.constraint(equalTo: booksCollectionView.trailingAnchor),
            booksLoadingView.bottomAnchor.constraint(equalTo: booksCollectionView.bottomAnchor),

            distanceHeader.topAnchor.constraint(equalTo: booksCollectionView.bottomAnchor, constant: AppSpacing.xl),
            distanceHeader.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            distanceHeader.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),

            distanceChipView.topAnchor.constraint(equalTo: distanceHeader.bottomAnchor, constant: AppSpacing.l),
            distanceChipView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            distanceChipView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            distanceChipView.heightAnchor.constraint(equalToConstant: 42),

            libraryHeader.topAnchor.constraint(equalTo: distanceChipView.bottomAnchor, constant: AppSpacing.xl),
            libraryHeader.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            libraryHeader.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),

            librariesCollectionView.topAnchor.constraint(equalTo: libraryHeader.bottomAnchor, constant: AppSpacing.l),
            librariesCollectionView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor),
            librariesCollectionView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor),
            librariesCollectionView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            librariesLoadingView.topAnchor.constraint(equalTo: librariesCollectionView.topAnchor),
            librariesLoadingView.leadingAnchor.constraint(equalTo: librariesCollectionView.leadingAnchor),
            librariesLoadingView.trailingAnchor.constraint(equalTo: librariesCollectionView.trailingAnchor),
            librariesLoadingView.bottomAnchor.constraint(equalTo: librariesCollectionView.bottomAnchor)
        ])

        accessibilityIdentifier = "searchScreen"
        backButton.accessibilityIdentifier = "search.backButton"
        librariesCollectionView.accessibilityIdentifier = "search.libraryCollection"
        booksCollectionView.accessibilityIdentifier = "search.bookCollection"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateLibraryHeaderTitle(_ title: String) {
        libraryHeader.updateTitle(title)
    }

    func updateExcludeToggleEnabled(_ isEnabled: Bool) {
        excludeToggle.isEnabled = isEnabled
    }

    func setBooksLoading(_ isLoading: Bool) {
        booksLoadingView.setLoading(isLoading)
    }

    func setLibrariesLoading(_ isLoading: Bool) {
        librariesLoadingView.setLoading(isLoading)
    }

    func updateLibraryMinimumHeight(isEmpty: Bool) {
        librariesCollectionView.minimumContentHeight = isEmpty ? 180 : 0
    }

    func observeBackPans(target: Any, action: Selector) {
        let capturePanGesture = UIPanGestureRecognizer(target: target, action: action)
        capturePanGesture.cancelsTouchesInView = false
        backCaptureView.addGestureRecognizer(capturePanGesture)
        scrollView.panGestureRecognizer.addTarget(target, action: action)
        booksCollectionView.panGestureRecognizer.addTarget(target, action: action)
        librariesCollectionView.panGestureRecognizer.addTarget(target, action: action)
    }

    private static func makeBooksLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .absolute(144),
                heightDimension: .absolute(216)
            ))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                widthDimension: .absolute(144),
                heightDimension: .absolute(216)
            ), subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
            section.interGroupSpacing = AppSpacing.m
            section.contentInsets = .zero
            return section
        }
    }

    private static func makeLibrariesLayout() -> UICollectionViewLayout {
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
#Preview("검색 결과") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)

    return SearchResultsViewController(
        viewModel: SearchResultsViewModel(
            searchRepository: dependencies.searchRepository,
            libraryRepository: dependencies.libraryRepository,
            currentLocation: AddressSuggestion(
                id: "preview-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "기본 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            currentDistance: .twoKm
        ),
        navigator: navigator
    )
}
#endif
