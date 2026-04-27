//
//  BookDetailViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class BookDetailViewController: UIViewController {
    private let viewModel: BookDetailViewModel
    private let contentView = BookDetailView()

    init(viewModel: BookDetailViewModel) {
        self.viewModel = viewModel
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
        contentView.favoriteButton.addAction(UIAction { [weak self] _ in
            Task { await self?.viewModel.didTapFavorite() }
        }, for: .touchUpInside)

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func render(_ state: BookDetailViewModel.State) {
        guard let detail = state.detail else { return }
        contentView.coverView.configure(seed: detail.id, imageURL: detail.coverImageURL)
        contentView.titleLabel.text = detail.title
        contentView.authorLabel.text = "저자: \(detail.author)"
        contentView.publisherLabel.text = "출판사: \(detail.publisher) · \(detail.year)"
        contentView.summaryLabel.text = detail.summary
        contentView.updateFavoriteButton(isFavorite: state.isFavorite, isLoading: state.isMutatingFavorite)
        contentView.updateFavoriteErrorMessage(state.errorMessage)
    }
}

private final class BookDetailView: UIView {
    let coverView = MockBookCoverView()
    let titleLabel = UILabel()
    let authorLabel = UILabel()
    let publisherLabel = UILabel()
    let favoriteButton = UIButton(type: .system)
    let summaryLabel = UILabel()
    private let favoriteErrorLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background
        accessibilityIdentifier = "bookDetailSheet"

        let scrollView = UIScrollView()
        let contentContainer = UIView()
        let metaCard = CardContainerView()
        let summaryTitle = UILabel()

        titleLabel.font = AppTypography.hero
        titleLabel.textColor = AppColor.textPrimary
        authorLabel.font = AppTypography.subheadline
        authorLabel.textColor = AppColor.textSecondary
        publisherLabel.font = AppTypography.caption
        publisherLabel.textColor = AppColor.textSecondary

        favoriteButton.layer.cornerCurve = .continuous
        favoriteButton.accessibilityIdentifier = "bookDetail.favoriteButton"

        favoriteErrorLabel.font = AppTypography.caption
        favoriteErrorLabel.textColor = AppColor.danger
        favoriteErrorLabel.numberOfLines = 2
        favoriteErrorLabel.isHidden = true

        summaryTitle.text = "책 소개"
        summaryTitle.font = AppTypography.section
        summaryTitle.textColor = AppColor.textPrimary

        summaryLabel.font = AppTypography.body
        summaryLabel.textColor = AppColor.textPrimary
        summaryLabel.numberOfLines = 0

        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.pinEdges(to: self)
        scrollView.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentContainer.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainer.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])

        contentContainer.addSubviews(metaCard, summaryTitle, summaryLabel)
        [metaCard, summaryTitle, summaryLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        metaCard.addSubviews(coverView, titleLabel, authorLabel, publisherLabel, favoriteButton, favoriteErrorLabel)
        [coverView, titleLabel, authorLabel, publisherLabel, favoriteButton, favoriteErrorLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let favoriteButtonTopConstraint = favoriteButton.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: AppSpacing.l)
        favoriteButtonTopConstraint.priority = .defaultHigh

        NSLayoutConstraint.activate([
            metaCard.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: AppSpacing.xxl),
            metaCard.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: AppSpacing.xxl),
            metaCard.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -AppSpacing.xxl),

            coverView.topAnchor.constraint(equalTo: metaCard.topAnchor, constant: AppSpacing.l),
            coverView.leadingAnchor.constraint(equalTo: metaCard.leadingAnchor, constant: AppSpacing.l),
            coverView.widthAnchor.constraint(equalToConstant: 112),
            coverView.heightAnchor.constraint(equalToConstant: 156),

            titleLabel.topAnchor.constraint(equalTo: coverView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: coverView.trailingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(equalTo: metaCard.trailingAnchor, constant: -AppSpacing.l),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.s),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            publisherLabel.topAnchor.constraint(equalTo: authorLabel.bottomAnchor, constant: AppSpacing.xs),
            publisherLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            publisherLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            favoriteButtonTopConstraint,
            favoriteButton.topAnchor.constraint(greaterThanOrEqualTo: publisherLabel.bottomAnchor, constant: AppSpacing.l),
            favoriteButton.leadingAnchor.constraint(equalTo: metaCard.leadingAnchor, constant: AppSpacing.l),
            favoriteButton.trailingAnchor.constraint(equalTo: metaCard.trailingAnchor, constant: -AppSpacing.l),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),

            favoriteErrorLabel.topAnchor.constraint(equalTo: favoriteButton.bottomAnchor, constant: AppSpacing.s),
            favoriteErrorLabel.leadingAnchor.constraint(equalTo: favoriteButton.leadingAnchor),
            favoriteErrorLabel.trailingAnchor.constraint(equalTo: favoriteButton.trailingAnchor),
            favoriteErrorLabel.bottomAnchor.constraint(equalTo: metaCard.bottomAnchor, constant: -AppSpacing.l),

            metaCard.bottomAnchor.constraint(greaterThanOrEqualTo: coverView.bottomAnchor, constant: AppSpacing.l),

            summaryTitle.topAnchor.constraint(equalTo: metaCard.bottomAnchor, constant: AppSpacing.xxl),
            summaryTitle.leadingAnchor.constraint(equalTo: metaCard.leadingAnchor),
            summaryTitle.trailingAnchor.constraint(equalTo: metaCard.trailingAnchor),

            summaryLabel.topAnchor.constraint(equalTo: summaryTitle.bottomAnchor, constant: AppSpacing.m),
            summaryLabel.leadingAnchor.constraint(equalTo: summaryTitle.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: summaryTitle.trailingAnchor),
            summaryLabel.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -AppSpacing.xxxl)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateFavoriteButton(isFavorite: Bool, isLoading: Bool) {
        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .medium
        configuration.baseBackgroundColor = isFavorite ? AppColor.heart : AppColor.accent
        configuration.baseForegroundColor = .white
        configuration.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        configuration.imagePadding = AppSpacing.s
        configuration.title = isFavorite ? "책 찜 해제" : "책 찜하기"
        configuration.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        favoriteButton.configuration = configuration
        favoriteButton.isEnabled = isLoading == false
        favoriteButton.alpha = isLoading ? 0.6 : 1
        favoriteButton.accessibilityLabel = isFavorite ? "책 찜 해제" : "책 찜하기"
    }

    func updateFavoriteErrorMessage(_ message: String?) {
        favoriteErrorLabel.text = message
        favoriteErrorLabel.isHidden = message == nil
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("도서 상세") {
    let dependencies = AppDependencies.mock

    return BookDetailViewController(
        viewModel: BookDetailViewModel(
            bookID: "book-arond-2",
            bookRepository: dependencies.bookRepository,
            favoritesRepository: dependencies.favoritesRepository
        )
    )
}
#endif
