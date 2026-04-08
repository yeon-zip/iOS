//
//  CommonCells.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

final class BookCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "BookCarouselCell"

    private let containerView = CardContainerView()
    private let coverView = UIView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let actionIcon = UIImageView(image: UIImage(systemName: "doc.text.viewfinder"))

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: contentView)

        coverView.backgroundColor = AppColor.elevated
        coverView.layer.cornerRadius = AppRadius.medium
        coverView.layer.cornerCurve = .continuous

        titleLabel.font = AppTypography.subheadline
        titleLabel.textColor = AppColor.textPrimary
        authorLabel.font = AppTypography.caption
        authorLabel.textColor = AppColor.textSecondary
        actionIcon.tintColor = AppColor.textSecondary

        containerView.addSubviews(coverView, titleLabel, authorLabel, actionIcon)
        [coverView, titleLabel, authorLabel, actionIcon].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: AppSpacing.l),
            coverView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            coverView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),
            coverView.heightAnchor.constraint(equalToConstant: 116),

            actionIcon.topAnchor.constraint(equalTo: coverView.topAnchor, constant: AppSpacing.s),
            actionIcon.trailingAnchor.constraint(equalTo: coverView.trailingAnchor, constant: -AppSpacing.s),
            actionIcon.widthAnchor.constraint(equalToConstant: 18),
            actionIcon.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.xs),
            authorLabel.leadingAnchor.constraint(equalTo: coverView.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: coverView.trailingAnchor),
            authorLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppSpacing.l)
        ])

        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColor.line.cgColor
        accessibilityIdentifier = "bookCarouselCell"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(viewData: BookCarouselItemViewData) {
        titleLabel.text = viewData.title
        authorLabel.text = viewData.subtitle
        containerView.layer.borderColor = (viewData.isFeatured ? AppColor.textPrimary : AppColor.line).cgColor
        containerView.layer.borderWidth = viewData.isFeatured ? 2 : 1
    }
}

final class LibraryCardCell: UICollectionViewCell {
    static let reuseIdentifier = "LibraryCardCell"

    private let containerView = CardContainerView()
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let badgeStack = UIStackView()
    private let actionsStack = UIStackView()
    private let bellButton = IconActionButton(symbolName: "bell", accessibilityLabel: "알림 토글")
    private let heartButton = IconActionButton(symbolName: "heart", accessibilityLabel: "찜 토글")

    var onBellTap: (() -> Void)?
    var onHeartTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: contentView)

        titleLabel.font = AppTypography.subheadline
        titleLabel.textColor = AppColor.textPrimary
        distanceLabel.font = AppTypography.body
        distanceLabel.textColor = AppColor.textPrimary

        badgeStack.axis = .horizontal
        badgeStack.spacing = AppSpacing.xs
        badgeStack.alignment = .center

        actionsStack.axis = .horizontal
        actionsStack.spacing = AppSpacing.s
        actionsStack.alignment = .center
        actionsStack.addArrangedSubview(bellButton)
        actionsStack.addArrangedSubview(heartButton)

        containerView.addSubviews(titleLabel, distanceLabel, badgeStack, actionsStack)
        [titleLabel, distanceLabel, badgeStack, actionsStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),

            actionsStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),

            distanceLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.m),
            distanceLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),
            distanceLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppSpacing.l),

            badgeStack.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: AppSpacing.s),
            badgeStack.centerYAnchor.constraint(equalTo: distanceLabel.centerYAnchor),
            badgeStack.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m)
        ])

        bellButton.addAction(UIAction { [weak self] _ in
            self?.onBellTap?()
        }, for: .touchUpInside)
        heartButton.addAction(UIAction { [weak self] _ in
            self?.onHeartTap?()
        }, for: .touchUpInside)
        accessibilityIdentifier = "libraryCardCell"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBellTap = nil
        onHeartTap = nil
        badgeStack.arrangedSubviews.forEach { view in
            badgeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configure(viewData: LibraryCardItemViewData) {
        titleLabel.text = viewData.title
        distanceLabel.text = viewData.distanceText
        bellButton.isHidden = viewData.showsBell == false
        bellButton.setSymbolName(viewData.isBellActive ? "bell.fill" : "bell")
        bellButton.accessibilityLabel = viewData.isBellActive ? "알림 해제" : "알림 설정"
        heartButton.setSymbolName(viewData.isFavorite ? "heart.fill" : "heart")
        heartButton.accessibilityLabel = viewData.isFavorite ? "찜 해제" : "찜하기"

        for badge in viewData.badges {
            badgeStack.addArrangedSubview(StatusBadgeView(content: badge))
        }
    }
}

class BookInfoCardCell: UICollectionViewCell {
    let containerView = CardContainerView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let badgeStack = UIStackView()
    let actionsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: contentView)

        titleLabel.font = AppTypography.subheadline
        titleLabel.textColor = AppColor.textPrimary
        subtitleLabel.font = AppTypography.caption
        subtitleLabel.textColor = AppColor.textSecondary

        badgeStack.axis = .horizontal
        badgeStack.spacing = AppSpacing.xs
        actionsStack.axis = .horizontal
        actionsStack.spacing = AppSpacing.s
        actionsStack.alignment = .center

        containerView.addSubviews(titleLabel, subtitleLabel, badgeStack, actionsStack)
        [titleLabel, subtitleLabel, badgeStack, actionsStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),

            actionsStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.xs),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),

            badgeStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: AppSpacing.m),
            badgeStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            badgeStack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -AppSpacing.l),
            badgeStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppSpacing.l)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        badgeStack.arrangedSubviews.forEach { view in
            badgeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configure(title: String, subtitle: String, badges: [BadgeContent]) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        for badge in badges {
            badgeStack.addArrangedSubview(StatusBadgeView(content: badge))
        }
    }
}

final class FavoriteBookCell: BookInfoCardCell {
    static let reuseIdentifier = "FavoriteBookCell"
    private let bellButton = IconActionButton(symbolName: "bell", accessibilityLabel: "알림 토글")
    private let heartButton = IconActionButton(symbolName: "heart", accessibilityLabel: "찜 토글")

    var onBellTap: (() -> Void)?
    var onHeartTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        actionsStack.addArrangedSubview(bellButton)
        actionsStack.addArrangedSubview(heartButton)
        bellButton.addAction(UIAction { [weak self] _ in
            self?.onBellTap?()
        }, for: .touchUpInside)
        heartButton.addAction(UIAction { [weak self] _ in
            self?.onHeartTap?()
        }, for: .touchUpInside)
        accessibilityIdentifier = "favoriteBookCell"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBellTap = nil
        onHeartTap = nil
    }

    func configure(viewData: FavoriteBookItemViewData) {
        configure(title: viewData.title, subtitle: viewData.subtitle, badges: viewData.badges)
        bellButton.setSymbolName(viewData.isAlertEnabled ? "bell.fill" : "bell")
        bellButton.accessibilityLabel = viewData.isAlertEnabled ? "알림 해제" : "알림 설정"
        heartButton.setSymbolName(viewData.isFavorite ? "heart.fill" : "heart")
        heartButton.accessibilityLabel = viewData.isFavorite ? "찜 해제" : "찜하기"
    }
}

final class AlertBookCell: BookInfoCardCell {
    static let reuseIdentifier = "AlertBookCell"
    private let bellButton = IconActionButton(symbolName: "bell", accessibilityLabel: "알림 토글")

    var onBellTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        actionsStack.addArrangedSubview(bellButton)
        bellButton.addAction(UIAction { [weak self] _ in
            self?.onBellTap?()
        }, for: .touchUpInside)
        accessibilityIdentifier = "alertBookCell"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onBellTap = nil
    }

    func configure(viewData: AlertBookItemViewData) {
        configure(title: viewData.title, subtitle: viewData.subtitle, badges: viewData.badges)
        bellButton.setSymbolName(viewData.isAlertEnabled ? "bell.fill" : "bell")
        bellButton.accessibilityLabel = viewData.isAlertEnabled ? "알림 해제" : "알림 설정"
    }
}
