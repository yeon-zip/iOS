//
//  CommonCells.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

final class MockBookCoverView: UIView {
    private static let imageCache = NSCache<NSURL, UIImage>()

    private let gradientLayer = CAGradientLayer()
    private let imageView = UIImageView()
    private let iconView = UIImageView(image: UIImage(systemName: "book.closed.fill"))
    private let accentCircle = UIView()
    private var imageTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
        layer.cornerCurve = .continuous
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true
        accentCircle.layer.cornerCurve = .continuous
        accentCircle.alpha = 0.22
        iconView.tintColor = UIColor.white.withAlphaComponent(0.95)
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)

        addSubviews(imageView, accentCircle, iconView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        accentCircle.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentCircle.widthAnchor.constraint(equalToConstant: 96),
            accentCircle.heightAnchor.constraint(equalToConstant: 96),
            accentCircle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 28),
            accentCircle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 32),

            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.l),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -AppSpacing.l)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        layer.cornerRadius = AppRadius.medium
        accentCircle.layer.cornerRadius = accentCircle.bounds.width / 2
    }

    func configure(seed: String, imageURL: URL? = nil) {
        imageTask?.cancel()
        imageView.image = nil

        let palettes: [[UIColor]] = [
            [UIColor(hex: 0x5B8CFF), UIColor(hex: 0x8DB8FF)],
            [UIColor(hex: 0x2D4E86), UIColor(hex: 0x5D7EB3)],
            [UIColor(hex: 0x2F9E9B), UIColor(hex: 0x67C4C1)],
            [UIColor(hex: 0x7A5AF8), UIColor(hex: 0xA48BFF)],
            [UIColor(hex: 0xF58A4B), UIColor(hex: 0xFFC289)],
            [UIColor(hex: 0xE35D93), UIColor(hex: 0xF3A3C4)]
        ]
        let paletteIndex = seed.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        } % palettes.count
        let colors = palettes[paletteIndex]
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        accentCircle.backgroundColor = UIColor.white
        imageView.isHidden = true
        iconView.isHidden = false
        accentCircle.isHidden = false

        guard let imageURL else { return }
        if let cachedImage = Self.imageCache.object(forKey: imageURL as NSURL) {
            applyLoadedImage(cachedImage)
            return
        }

        imageTask = Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                guard Task.isCancelled == false, let image = UIImage(data: data) else { return }
                Self.imageCache.setObject(image, forKey: imageURL as NSURL)
                await MainActor.run {
                    self?.applyLoadedImage(image)
                }
            } catch {
                // Keep the gradient fallback when the cover image cannot be loaded.
            }
        }
    }

    private func applyLoadedImage(_ image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        iconView.isHidden = true
        accentCircle.isHidden = true
    }
}

final class BookCarouselCell: UICollectionViewCell {
    static let reuseIdentifier = "BookCarouselCell"

    private let containerView = CardContainerView()
    private let coverView = MockBookCoverView()
    private let titleLabel = UILabel()
    private let authorLabel = UILabel()
    private let detailButton = UIButton(type: .system)

    var onDetailTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: contentView)

        titleLabel.font = AppTypography.subheadline
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        authorLabel.font = AppTypography.caption
        authorLabel.textColor = AppColor.textSecondary
        detailButton.accessibilityIdentifier = "bookCarouselCell.detailButton"
        detailButton.accessibilityLabel = "책 상세 정보"
        detailButton.showsMenuAsPrimaryAction = false
        detailButton.layer.cornerCurve = .continuous

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "doc.text.viewfinder")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        configuration.baseForegroundColor = UIColor.white.withAlphaComponent(0.92)
        configuration.background.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        configuration.background.cornerRadius = 12
        configuration.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        detailButton.configuration = configuration

        containerView.addSubviews(coverView, titleLabel, authorLabel, detailButton)
        [coverView, titleLabel, authorLabel, detailButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            coverView.topAnchor.constraint(equalTo: containerView.topAnchor),
            coverView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            coverView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            coverView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.69),

            detailButton.topAnchor.constraint(equalTo: coverView.topAnchor, constant: AppSpacing.m),
            detailButton.trailingAnchor.constraint(equalTo: coverView.trailingAnchor, constant: -AppSpacing.m),
            detailButton.widthAnchor.constraint(equalToConstant: 28),
            detailButton.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.topAnchor.constraint(equalTo: coverView.bottomAnchor, constant: AppSpacing.m),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.m),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.m),

            authorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.xs),
            authorLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            authorLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            authorLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppSpacing.m)
        ])

        detailButton.addAction(UIAction { [weak self] _ in
            self?.onDetailTap?()
        }, for: .touchUpInside)
        accessibilityIdentifier = "bookCarouselCell"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDetailTap = nil
    }

    func configure(viewData: BookCarouselItemViewData) {
        titleLabel.text = viewData.title
        authorLabel.text = viewData.subtitle
        coverView.configure(seed: viewData.id, imageURL: viewData.coverImageURL)
        containerView.layer.borderColor = (viewData.isSelected ? AppColor.accent : AppColor.line).cgColor
        containerView.layer.borderWidth = viewData.isSelected ? 2 : 1
    }
}

final class LibraryCardCell: UICollectionViewCell {
    static let reuseIdentifier = "LibraryCardCell"

    private let containerView = CardContainerView()
    private let titleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let metadataStack = UIStackView()
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
        titleLabel.numberOfLines = 2
        distanceLabel.font = AppTypography.body
        distanceLabel.textColor = AppColor.textPrimary

        metadataStack.axis = .vertical
        metadataStack.spacing = AppSpacing.s
        metadataStack.alignment = .leading
        metadataStack.addArrangedSubview(distanceLabel)
        metadataStack.addArrangedSubview(badgeStack)

        badgeStack.axis = .horizontal
        badgeStack.spacing = AppSpacing.s
        badgeStack.alignment = .center

        actionsStack.axis = .horizontal
        actionsStack.spacing = 2
        actionsStack.alignment = .center
        actionsStack.addArrangedSubview(bellButton)
        actionsStack.addArrangedSubview(heartButton)

        containerView.addSubviews(titleLabel, metadataStack, actionsStack)
        [titleLabel, metadataStack, actionsStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),

            actionsStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),

            metadataStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.l),
            metadataStack.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metadataStack.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),
            metadataStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -AppSpacing.l)
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
        heartButton.isHidden = viewData.showsFavorite == false
        bellButton.setSymbolName(viewData.isBellActive ? "bell.fill" : "bell")
        bellButton.accessibilityLabel = viewData.isBellActive ? "알림 해제" : "알림 설정"
        bellButton.setForegroundColor(viewData.isBellActive ? AppColor.accent : AppColor.textTertiary)
        heartButton.setSymbolName(viewData.isFavorite ? "heart.fill" : "heart")
        heartButton.accessibilityLabel = viewData.isFavorite ? "찜 해제" : "찜하기"
        heartButton.setForegroundColor(viewData.isFavorite ? AppColor.heart : AppColor.textTertiary)

        for badge in viewData.badges {
            badgeStack.addArrangedSubview(StatusBadgeView(content: badge))
        }
    }
}

class BookInfoCardCell: UICollectionViewCell {
    let containerView = CardContainerView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let supportingLabel = UILabel()
    let badgeStack = UIStackView()
    let actionsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: contentView)

        titleLabel.font = AppTypography.subheadline
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.numberOfLines = 2
        subtitleLabel.font = AppTypography.caption
        subtitleLabel.textColor = AppColor.textSecondary
        subtitleLabel.numberOfLines = 2
        supportingLabel.font = AppTypography.tiny
        supportingLabel.textColor = AppColor.accent
        supportingLabel.numberOfLines = 1
        supportingLabel.isHidden = true

        badgeStack.axis = .horizontal
        badgeStack.spacing = AppSpacing.s
        actionsStack.axis = .horizontal
        actionsStack.spacing = 2
        actionsStack.alignment = .center

        containerView.addSubviews(titleLabel, subtitleLabel, supportingLabel, badgeStack, actionsStack)
        [titleLabel, subtitleLabel, supportingLabel, badgeStack, actionsStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: AppSpacing.l),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),

            actionsStack.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            actionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: AppSpacing.xs),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionsStack.leadingAnchor, constant: -AppSpacing.m),

            supportingLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 6),
            supportingLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            supportingLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -AppSpacing.l),

            badgeStack.topAnchor.constraint(equalTo: supportingLabel.bottomAnchor, constant: AppSpacing.l),
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
        supportingLabel.text = nil
        supportingLabel.isHidden = true
        badgeStack.arrangedSubviews.forEach { view in
            badgeStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configure(title: String, subtitle: String, supportingText: String? = nil, badges: [BadgeContent]) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        supportingLabel.text = supportingText
        supportingLabel.isHidden = supportingText?.isEmpty != false
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
        bellButton.setForegroundColor(viewData.isAlertEnabled ? AppColor.accent : AppColor.textTertiary)
        heartButton.setSymbolName(viewData.isFavorite ? "heart.fill" : "heart")
        heartButton.accessibilityLabel = viewData.isFavorite ? "찜 해제" : "찜하기"
        heartButton.setForegroundColor(viewData.isFavorite ? AppColor.heart : AppColor.textTertiary)
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
        configure(
            title: viewData.title,
            subtitle: viewData.metadataText,
            supportingText: "알림 도서관 · \(viewData.libraryName)",
            badges: viewData.badges
        )
        bellButton.setSymbolName(viewData.isAlertEnabled ? "bell.fill" : "bell")
        bellButton.accessibilityLabel = viewData.isAlertEnabled ? "알림 해제" : "알림 설정"
        bellButton.setForegroundColor(viewData.isAlertEnabled ? AppColor.accent : AppColor.textTertiary)
    }
}
