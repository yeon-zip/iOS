//
//  HomeViewController.swift
//  Polaris
//
//  Created by 손유나 on 4/4/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class HomeViewController: BaseViewController, UICollectionViewDelegate, LocationSelectionHandling {
    private static let librariesSection = 0

    private let viewModel: HomeViewModel
    private let searchViewModel: SearchResultsViewModel
    private weak var navigator: AppNavigator?
    private let contentView = HomeView()
    private lazy var homeDataSource = makeHomeDataSource()
    private lazy var searchBooksDataSource = makeSearchBooksDataSource()
    private lazy var searchLibrariesDataSource = makeSearchLibrariesDataSource()
    private var isShowingSearchResults = false

    init(viewModel: HomeViewModel, searchViewModel: SearchResultsViewModel, navigator: AppNavigator) {
        self.viewModel = viewModel
        self.searchViewModel = searchViewModel
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
        contentView.homeCollectionView.delegate = self
        contentView.searchBooksCollectionView.delegate = self
        contentView.searchLibrariesCollectionView.delegate = self
        contentView.locationButton.addAction(UIAction { [weak self] _ in
            self?.viewModel.didTapLocationPicker()
        }, for: .touchUpInside)
        contentView.searchInputView.isEditable = true
        contentView.searchInputView.onSubmit = { [weak self] query in
            self?.handleInlineSearchSubmit(query)
        }
        contentView.searchInputView.onTextChanged = { [weak self] text in
            self?.handleInlineSearchTextChanged(text)
        }
        contentView.homeDistanceChipView.onSelectionChanged = { [weak self] distance in
            self?.viewModel.didSelectDistance(distance)
        }
        contentView.homeExcludeToggle.onToggle = { [weak self] isOn in
            self?.viewModel.didToggleExcludeClosed(isOn)
        }
        contentView.searchDistanceChipView.onSelectionChanged = { [weak self] distance in
            self?.searchViewModel.didSelectDistance(distance)
        }
        contentView.searchExcludeToggle.onToggle = { [weak self] isOn in
            self?.searchViewModel.didToggleExcludeUnavailable(isOn)
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
            self?.renderHome(state)
        }

        searchViewModel.onStateChange = { [weak self] state in
            self?.renderSearch(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }

        searchViewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func renderHome(_ state: HomeViewModel.State) {
        contentView.locationButton.update(address: state.selectedLocation.roadAddress)
        contentView.homeDistanceChipView.updateSelection(state.selectedDistance)
        contentView.homeExcludeToggle.isSelected = state.excludeClosed
        contentView.homeCollectionView.backgroundView = state.libraries.isEmpty
            ? EmptyStateView(title: "주변 도서관이 없어요", message: "검색 반경이나 필터를 바꿔서 다시 찾아보세요.")
            : nil

        var snapshot = NSDiffableDataSourceSnapshot<Int, LibraryCardItemViewData>()
        snapshot.appendSections([Self.librariesSection])
        snapshot.appendItems(state.libraries, toSection: Self.librariesSection)
        homeDataSource.apply(snapshot, animatingDifferences: false)
    }

    private func renderSearch(_ state: SearchResultsViewModel.State) {
        contentView.searchDistanceChipView.updateSelection(state.selectedDistance)
        contentView.searchExcludeToggle.isSelected = state.query.excludeUnavailable
        contentView.updateSearchExcludeToggleEnabled(state.selectedBookID != nil)
        contentView.setSearchBooksLoading(state.isBooksLoading)
        contentView.setSearchLibrariesLoading(state.isLibrariesLoading)
        contentView.updateSearchLibraryHeaderTitle(
            state.selectedBookID == nil ? "주변 도서관" : "주변 보유 도서관"
        )

        if state.isBooksLoading {
            contentView.searchBooksCollectionView.backgroundView = nil
        } else if state.books.isEmpty {
            contentView.searchBooksCollectionView.backgroundView = state.query.text.isEmpty
                ? EmptyStateView(title: "도서를 검색해보세요", message: "도서명, 저자, 출판사로 검색할 수 있어요.")
                : EmptyStateView(title: "도서를 찾지 못했어요", message: "도서명이나 저자를 조금 다르게 입력해보세요.")
        } else {
            contentView.searchBooksCollectionView.backgroundView = nil
        }

        contentView.searchLibrariesCollectionView.backgroundView = state.isLibrariesLoading
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
        bookSnapshot.appendSections([Self.librariesSection])
        bookSnapshot.appendItems(state.books, toSection: Self.librariesSection)
        searchBooksDataSource.apply(bookSnapshot, animatingDifferences: false)

        var librarySnapshot = NSDiffableDataSourceSnapshot<Int, LibraryCardItemViewData>()
        librarySnapshot.appendSections([Self.librariesSection])
        librarySnapshot.appendItems(state.libraries, toSection: Self.librariesSection)
        searchLibrariesDataSource.apply(librarySnapshot, animatingDifferences: false)
        contentView.updateSearchLibraryMinimumHeight(isEmpty: state.libraries.isEmpty || state.isLibrariesLoading)
    }

    private func handleInlineSearchSubmit(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        contentView.searchInputView.text = trimmedQuery

        guard trimmedQuery.isEmpty == false else {
            setSearchMode(false)
            return
        }

        if isShowingSearchResults == false {
            _ = searchViewModel.didSelectDistance(viewModel.state.selectedDistance)
        }
        setSearchMode(true)
        _ = searchViewModel.didSubmitQuery(trimmedQuery)
    }

    private func handleInlineSearchTextChanged(_ text: String) {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setSearchMode(false)
        }
    }

    private func setSearchMode(_ isSearchMode: Bool) {
        isShowingSearchResults = isSearchMode
        contentView.setSearchMode(isSearchMode)
        if isSearchMode {
            contentView.resetSearchScrollPosition()
        }
    }

    private func makeHomeDataSource() -> UICollectionViewDiffableDataSource<Int, LibraryCardItemViewData> {
        let registration = UICollectionView.CellRegistration<LibraryCardCell, LibraryCardItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onHeartTap = { [weak self] in
                self?.viewModel.didToggleFavorite(id: item.id)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.homeCollectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
    }

    private func makeSearchBooksDataSource() -> UICollectionViewDiffableDataSource<Int, BookCarouselItemViewData> {
        let registration = UICollectionView.CellRegistration<BookCarouselCell, BookCarouselItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onDetailTap = { [weak self] in
                self?.searchViewModel.didTapBookDetail(id: item.id)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.searchBooksCollectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
    }

    private func makeSearchLibrariesDataSource() -> UICollectionViewDiffableDataSource<Int, LibraryCardItemViewData> {
        let registration = UICollectionView.CellRegistration<LibraryCardCell, LibraryCardItemViewData> { [weak self] cell, _, item in
            cell.configure(viewData: item)
            cell.onBellTap = { [weak self] in
                self?.searchViewModel.didToggleLibraryAlert(id: item.id)
            }
            cell.onHeartTap = { [weak self] in
                self?.searchViewModel.didToggleLibraryFavorite(id: item.id)
            }
        }

        return UICollectionViewDiffableDataSource(collectionView: contentView.searchLibrariesCollectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: itemIdentifier)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == contentView.homeCollectionView,
           let library = homeDataSource.itemIdentifier(for: indexPath) {
            viewModel.didSelectLibrary(id: library.id)
        } else if collectionView == contentView.searchBooksCollectionView,
                  let book = searchBooksDataSource.itemIdentifier(for: indexPath) {
            _ = searchViewModel.didSelectBook(id: book.id)
        } else if collectionView == contentView.searchLibrariesCollectionView,
                  let library = searchLibrariesDataSource.itemIdentifier(for: indexPath) {
            searchViewModel.didSelectLibrary(id: library.id)
        }
    }

    func applySelectedLocation(_ suggestion: AddressSuggestion) {
        _ = viewModel.didUpdateLocation(suggestion)
        _ = searchViewModel.didUpdateLocation(suggestion)
    }
}

private final class HomeView: UIView {
    let locationButton = HomeLocationButton()
    let likeButton = IconActionButton(symbolName: "heart", style: .soft, accessibilityLabel: "찜 화면 열기")
    let alertButton = IconActionButton(symbolName: "bell", style: .soft, accessibilityLabel: "알림 화면 열기")
    let profileButton = IconActionButton(symbolName: "person.crop.circle", style: .soft, accessibilityLabel: "프로필 화면 열기")
    let searchInputView = SearchInputView(placeholder: "도서명, 저자, 출판사 검색")
    let homeDistanceChipView = FilterChipGroupView(options: DistanceOption.allCases, selected: .threeKm)
    let homeExcludeToggle = InlineToggleView(title: "운영종료 제외")
    let homeCollectionView: UICollectionView
    let searchBooksCollectionView: UICollectionView
    let searchDistanceChipView = FilterChipGroupView(options: DistanceOption.allCases, selected: .threeKm)
    let searchExcludeToggle = InlineToggleView(title: "대출불가 제외")
    let searchLibrariesCollectionView: ContentSizedCollectionView
    private let searchBooksLoadingView = LoadingOverlayView()
    private let searchLibrariesLoadingView = LoadingOverlayView()

    private let homeContentView = UIView()
    private let searchContentView = UIScrollView()
    private let searchContentContainer = UIView()
    private let homeDistanceHeader = SectionHeaderView(title: "검색 반경")
    private lazy var homeLibraryHeader = SectionHeaderView(title: "주변 도서관", accessoryView: homeExcludeToggle)
    private let searchDistanceHeader = SectionHeaderView(title: "검색 반경")
    private lazy var searchLibraryHeader = SectionHeaderView(title: "주변 도서관", accessoryView: searchExcludeToggle)

    override init(frame: CGRect) {
        homeCollectionView = UICollectionView(frame: .zero, collectionViewLayout: HomeView.makeLibrariesLayout())
        searchBooksCollectionView = UICollectionView(frame: .zero, collectionViewLayout: HomeView.makeBooksLayout())
        searchLibrariesCollectionView = ContentSizedCollectionView(frame: .zero, collectionViewLayout: HomeView.makeLibrariesLayout())
        super.init(frame: frame)
        backgroundColor = AppColor.background

        let actionStack = UIStackView(arrangedSubviews: [likeButton, alertButton, profileButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 6
        actionStack.alignment = .center
        actionStack.setContentHuggingPriority(.required, for: .horizontal)
        actionStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        locationButton.setContentHuggingPriority(.defaultLow, for: .horizontal)
        locationButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        searchInputView.isEditable = true
        homeCollectionView.backgroundColor = .clear
        searchBooksCollectionView.backgroundColor = .clear
        searchLibrariesCollectionView.backgroundColor = .clear
        searchContentView.alwaysBounceVertical = true
        searchContentView.showsVerticalScrollIndicator = true
        searchLibrariesCollectionView.isScrollEnabled = false

        addSubviews(locationButton, actionStack, searchInputView, homeContentView, searchContentView)
        [locationButton, actionStack, searchInputView, homeContentView, searchContentView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        searchContentView.addSubview(searchContentContainer)
        searchContentContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            locationButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.xl),
            locationButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            locationButton.trailingAnchor.constraint(equalTo: actionStack.leadingAnchor, constant: -AppSpacing.m),
            locationButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),

            actionStack.centerYAnchor.constraint(equalTo: locationButton.centerYAnchor),
            actionStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            searchInputView.topAnchor.constraint(equalTo: locationButton.bottomAnchor, constant: AppSpacing.l),
            searchInputView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            searchInputView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            homeContentView.topAnchor.constraint(equalTo: searchInputView.bottomAnchor, constant: AppSpacing.xl),
            homeContentView.leadingAnchor.constraint(equalTo: searchInputView.leadingAnchor),
            homeContentView.trailingAnchor.constraint(equalTo: searchInputView.trailingAnchor),
            homeContentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            searchContentView.topAnchor.constraint(equalTo: homeContentView.topAnchor),
            searchContentView.leadingAnchor.constraint(equalTo: homeContentView.leadingAnchor),
            searchContentView.trailingAnchor.constraint(equalTo: homeContentView.trailingAnchor),
            searchContentView.bottomAnchor.constraint(equalTo: homeContentView.bottomAnchor),

            searchContentContainer.topAnchor.constraint(equalTo: searchContentView.contentLayoutGuide.topAnchor),
            searchContentContainer.leadingAnchor.constraint(equalTo: searchContentView.contentLayoutGuide.leadingAnchor),
            searchContentContainer.trailingAnchor.constraint(equalTo: searchContentView.contentLayoutGuide.trailingAnchor),
            searchContentContainer.bottomAnchor.constraint(equalTo: searchContentView.contentLayoutGuide.bottomAnchor),
            searchContentContainer.widthAnchor.constraint(equalTo: searchContentView.frameLayoutGuide.widthAnchor)
        ])

        setupHomeContent()
        setupSearchContent()
        setSearchMode(false)

        accessibilityIdentifier = "homeScreen"
        locationButton.accessibilityIdentifier = "home.locationButton"
        searchInputView.accessibilityIdentifier = "home.searchInput"
        homeCollectionView.accessibilityIdentifier = "home.libraryCollection"
        searchBooksCollectionView.accessibilityIdentifier = "home.search.bookCollection"
        searchLibrariesCollectionView.accessibilityIdentifier = "home.search.libraryCollection"
        likeButton.accessibilityIdentifier = "home.likesButton"
        alertButton.accessibilityIdentifier = "home.alertsButton"
        profileButton.accessibilityIdentifier = "home.profileButton"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSearchMode(_ isSearchMode: Bool) {
        homeContentView.isHidden = isSearchMode
        searchContentView.isHidden = isSearchMode == false
    }

    func resetSearchScrollPosition() {
        searchContentView.setContentOffset(.zero, animated: false)
    }

    func updateSearchLibraryHeaderTitle(_ title: String) {
        searchLibraryHeader.updateTitle(title)
    }

    func updateSearchExcludeToggleEnabled(_ isEnabled: Bool) {
        searchExcludeToggle.isEnabled = isEnabled
    }

    func setSearchBooksLoading(_ isLoading: Bool) {
        searchBooksLoadingView.setLoading(isLoading)
    }

    func setSearchLibrariesLoading(_ isLoading: Bool) {
        searchLibrariesLoadingView.setLoading(isLoading)
    }

    func updateSearchLibraryMinimumHeight(isEmpty: Bool) {
        searchLibrariesCollectionView.minimumContentHeight = isEmpty ? 180 : 0
    }

    private func setupHomeContent() {
        homeContentView.addSubviews(homeDistanceHeader, homeDistanceChipView, homeLibraryHeader, homeCollectionView)
        [homeDistanceHeader, homeDistanceChipView, homeLibraryHeader, homeCollectionView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            homeDistanceHeader.topAnchor.constraint(equalTo: homeContentView.topAnchor),
            homeDistanceHeader.leadingAnchor.constraint(equalTo: homeContentView.leadingAnchor),
            homeDistanceHeader.trailingAnchor.constraint(equalTo: homeContentView.trailingAnchor),

            homeDistanceChipView.topAnchor.constraint(equalTo: homeDistanceHeader.bottomAnchor, constant: AppSpacing.l),
            homeDistanceChipView.leadingAnchor.constraint(equalTo: homeContentView.leadingAnchor),
            homeDistanceChipView.trailingAnchor.constraint(equalTo: homeContentView.trailingAnchor),
            homeDistanceChipView.heightAnchor.constraint(equalToConstant: 42),

            homeLibraryHeader.topAnchor.constraint(equalTo: homeDistanceChipView.bottomAnchor, constant: AppSpacing.xl),
            homeLibraryHeader.leadingAnchor.constraint(equalTo: homeContentView.leadingAnchor),
            homeLibraryHeader.trailingAnchor.constraint(equalTo: homeContentView.trailingAnchor),

            homeCollectionView.topAnchor.constraint(equalTo: homeLibraryHeader.bottomAnchor, constant: AppSpacing.l),
            homeCollectionView.leadingAnchor.constraint(equalTo: homeContentView.leadingAnchor),
            homeCollectionView.trailingAnchor.constraint(equalTo: homeContentView.trailingAnchor),
            homeCollectionView.bottomAnchor.constraint(equalTo: homeContentView.bottomAnchor)
        ])
    }

    private func setupSearchContent() {
        searchContentContainer.addSubviews(
            searchBooksCollectionView,
            searchBooksLoadingView,
            searchDistanceHeader,
            searchDistanceChipView,
            searchLibraryHeader,
            searchLibrariesCollectionView,
            searchLibrariesLoadingView
        )
        [searchBooksCollectionView, searchBooksLoadingView, searchDistanceHeader, searchDistanceChipView, searchLibraryHeader, searchLibrariesCollectionView, searchLibrariesLoadingView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            searchBooksCollectionView.topAnchor.constraint(equalTo: searchContentContainer.topAnchor),
            searchBooksCollectionView.leadingAnchor.constraint(equalTo: searchContentContainer.leadingAnchor),
            searchBooksCollectionView.trailingAnchor.constraint(equalTo: searchContentContainer.trailingAnchor),
            searchBooksCollectionView.heightAnchor.constraint(equalToConstant: 220),

            searchBooksLoadingView.topAnchor.constraint(equalTo: searchBooksCollectionView.topAnchor),
            searchBooksLoadingView.leadingAnchor.constraint(equalTo: searchBooksCollectionView.leadingAnchor),
            searchBooksLoadingView.trailingAnchor.constraint(equalTo: searchBooksCollectionView.trailingAnchor),
            searchBooksLoadingView.bottomAnchor.constraint(equalTo: searchBooksCollectionView.bottomAnchor),

            searchDistanceHeader.topAnchor.constraint(equalTo: searchBooksCollectionView.bottomAnchor, constant: AppSpacing.xl),
            searchDistanceHeader.leadingAnchor.constraint(equalTo: searchContentContainer.leadingAnchor),
            searchDistanceHeader.trailingAnchor.constraint(equalTo: searchContentContainer.trailingAnchor),

            searchDistanceChipView.topAnchor.constraint(equalTo: searchDistanceHeader.bottomAnchor, constant: AppSpacing.l),
            searchDistanceChipView.leadingAnchor.constraint(equalTo: searchContentContainer.leadingAnchor),
            searchDistanceChipView.trailingAnchor.constraint(equalTo: searchContentContainer.trailingAnchor),
            searchDistanceChipView.heightAnchor.constraint(equalToConstant: 42),

            searchLibraryHeader.topAnchor.constraint(equalTo: searchDistanceChipView.bottomAnchor, constant: AppSpacing.xl),
            searchLibraryHeader.leadingAnchor.constraint(equalTo: searchContentContainer.leadingAnchor),
            searchLibraryHeader.trailingAnchor.constraint(equalTo: searchContentContainer.trailingAnchor),

            searchLibrariesCollectionView.topAnchor.constraint(equalTo: searchLibraryHeader.bottomAnchor, constant: AppSpacing.l),
            searchLibrariesCollectionView.leadingAnchor.constraint(equalTo: searchContentContainer.leadingAnchor),
            searchLibrariesCollectionView.trailingAnchor.constraint(equalTo: searchContentContainer.trailingAnchor),
            searchLibrariesCollectionView.bottomAnchor.constraint(equalTo: searchContentContainer.bottomAnchor),

            searchLibrariesLoadingView.topAnchor.constraint(equalTo: searchLibrariesCollectionView.topAnchor),
            searchLibrariesLoadingView.leadingAnchor.constraint(equalTo: searchLibrariesCollectionView.leadingAnchor),
            searchLibrariesLoadingView.trailingAnchor.constraint(equalTo: searchLibrariesCollectionView.trailingAnchor),
            searchLibrariesLoadingView.bottomAnchor.constraint(equalTo: searchLibrariesCollectionView.bottomAnchor)
        ])
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

private final class HomeLocationButton: UIControl {
    private let addressLabel = UILabel()
    private let locationIconView = UIImageView(image: UIImage(systemName: "location.fill"))
    private let chevronView = UIImageView(image: UIImage(systemName: "chevron.down"))
    private let contentContainer = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentContainer.isUserInteractionEnabled = false

        addressLabel.font = AppTypography.headline
        addressLabel.textColor = AppColor.textPrimary
        addressLabel.numberOfLines = 1
        addressLabel.lineBreakMode = .byTruncatingTail

        locationIconView.tintColor = AppColor.accent
        locationIconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        locationIconView.contentMode = .scaleAspectFit
        locationIconView.setContentHuggingPriority(.required, for: .horizontal)
        locationIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        chevronView.tintColor = AppColor.textSecondary
        chevronView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        chevronView.contentMode = .scaleAspectFit
        chevronView.setContentHuggingPriority(.required, for: .horizontal)
        chevronView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let addressRow = UIStackView(arrangedSubviews: [locationIconView, addressLabel, chevronView])
        addressRow.axis = .horizontal
        addressRow.spacing = AppSpacing.xs
        addressRow.alignment = .center
        addressRow.isUserInteractionEnabled = false

        addSubview(contentContainer)
        contentContainer.addSubview(addressRow)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        addressRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            addressRow.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 10),
            addressRow.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: AppSpacing.m),
            addressRow.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -AppSpacing.m),
            addressRow.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -10),

            locationIconView.widthAnchor.constraint(equalToConstant: 14),
            locationIconView.heightAnchor.constraint(equalToConstant: 14),
            chevronView.widthAnchor.constraint(equalToConstant: 12),
            chevronView.heightAnchor.constraint(equalToConstant: 12)
        ])

        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(address: String) {
        addressLabel.text = address
        accessibilityLabel = "현재 주소 \(address)"
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -12, dy: -12).contains(point)
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("홈") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)
    let homeViewModel = HomeViewModel(libraryRepository: dependencies.libraryRepository)
    let searchViewModel = SearchResultsViewModel(
        searchRepository: dependencies.searchRepository,
        libraryRepository: dependencies.libraryRepository,
        currentLocation: homeViewModel.state.selectedLocation,
        currentDistance: homeViewModel.state.selectedDistance
    )

    return HomeViewController(
        viewModel: homeViewModel,
        searchViewModel: searchViewModel,
        navigator: navigator
    )
}
#endif
