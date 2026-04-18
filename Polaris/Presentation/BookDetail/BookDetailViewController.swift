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
    }
}

private final class BookDetailView: UIView {
    let coverView = MockBookCoverView()
    let titleLabel = UILabel()
    let authorLabel = UILabel()
    let publisherLabel = UILabel()
    let summaryLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background
        accessibilityIdentifier = "bookDetailSheet"

        let scrollView = UIScrollView()
        let contentContainer = UIView()
        let metaCard = CardContainerView()
        let decisionCard = CardContainerView()
        let decisionTitle = UILabel()
        let yesButton = UIButton(type: .system)
        let noButton = UIButton(type: .system)
        let summaryTitle = UILabel()

        titleLabel.font = AppTypography.hero
        titleLabel.textColor = AppColor.textPrimary
        authorLabel.font = AppTypography.subheadline
        authorLabel.textColor = AppColor.textSecondary
        publisherLabel.font = AppTypography.caption
        publisherLabel.textColor = AppColor.textSecondary

        summaryTitle.text = "책 소개"
        summaryTitle.font = AppTypography.section
        summaryTitle.textColor = AppColor.textPrimary

        summaryLabel.font = AppTypography.body
        summaryLabel.textColor = AppColor.textPrimary
        summaryLabel.numberOfLines = 0

        decisionTitle.text = "소장 투표 API 미구현"
        decisionTitle.font = AppTypography.headline
        decisionTitle.textColor = AppColor.textPrimary

        var yesConfiguration = UIButton.Configuration.filled()
        yesConfiguration.cornerStyle = .capsule
        yesConfiguration.baseBackgroundColor = AppColor.accent
        yesConfiguration.baseForegroundColor = .white
        yesConfiguration.contentInsets = .init(top: 10, leading: 18, bottom: 10, trailing: 18)
        yesConfiguration.title = "예"
        yesConfiguration.image = UIImage(systemName: "hand.thumbsup.fill")
        yesButton.configuration = yesConfiguration

        var noConfiguration = UIButton.Configuration.filled()
        noConfiguration.cornerStyle = .capsule
        noConfiguration.baseBackgroundColor = AppColor.surface
        noConfiguration.baseForegroundColor = AppColor.textSecondary
        noConfiguration.background.strokeColor = AppColor.line
        noConfiguration.background.strokeWidth = 1
        noConfiguration.contentInsets = .init(top: 10, leading: 18, bottom: 10, trailing: 18)
        noConfiguration.title = "아니오"
        noConfiguration.image = UIImage(systemName: "hand.thumbsdown")
        noButton.configuration = noConfiguration

        [yesButton, noButton].forEach { button in
            button.layer.cornerCurve = .continuous
            button.isEnabled = false
            button.alpha = 0.5
        }

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

        contentContainer.addSubviews(metaCard, decisionCard, summaryTitle, summaryLabel)
        [metaCard, decisionCard, summaryTitle, summaryLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        metaCard.addSubviews(coverView, titleLabel, authorLabel, publisherLabel)
        [coverView, titleLabel, authorLabel, publisherLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        decisionCard.addSubviews(decisionTitle, yesButton, noButton)
        [decisionTitle, yesButton, noButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

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
            publisherLabel.bottomAnchor.constraint(lessThanOrEqualTo: metaCard.bottomAnchor, constant: -AppSpacing.l),

            metaCard.bottomAnchor.constraint(greaterThanOrEqualTo: coverView.bottomAnchor, constant: AppSpacing.l),
            metaCard.bottomAnchor.constraint(greaterThanOrEqualTo: publisherLabel.bottomAnchor, constant: AppSpacing.l),

            decisionCard.topAnchor.constraint(equalTo: metaCard.bottomAnchor, constant: AppSpacing.l),
            decisionCard.leadingAnchor.constraint(equalTo: metaCard.leadingAnchor),
            decisionCard.trailingAnchor.constraint(equalTo: metaCard.trailingAnchor),

            decisionTitle.topAnchor.constraint(equalTo: decisionCard.topAnchor, constant: AppSpacing.l),
            decisionTitle.leadingAnchor.constraint(equalTo: decisionCard.leadingAnchor, constant: AppSpacing.l),
            decisionTitle.trailingAnchor.constraint(equalTo: decisionCard.trailingAnchor, constant: -AppSpacing.l),

            yesButton.topAnchor.constraint(equalTo: decisionTitle.bottomAnchor, constant: AppSpacing.l),
            yesButton.leadingAnchor.constraint(equalTo: decisionTitle.leadingAnchor),
            yesButton.bottomAnchor.constraint(equalTo: decisionCard.bottomAnchor, constant: -AppSpacing.l),

            noButton.topAnchor.constraint(equalTo: yesButton.topAnchor),
            noButton.leadingAnchor.constraint(equalTo: yesButton.trailingAnchor, constant: AppSpacing.m),
            noButton.trailingAnchor.constraint(lessThanOrEqualTo: decisionCard.trailingAnchor, constant: -AppSpacing.l),
            noButton.bottomAnchor.constraint(equalTo: yesButton.bottomAnchor),

            summaryTitle.topAnchor.constraint(equalTo: decisionCard.bottomAnchor, constant: AppSpacing.xxl),
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
}

#if DEBUG && canImport(SwiftUI)
#Preview("도서 상세") {
    let dependencies = AppDependencies.mock

    return BookDetailViewController(
        viewModel: BookDetailViewModel(
            bookID: "book-arond-2",
            bookRepository: dependencies.bookRepository
        )
    )
}
#endif
