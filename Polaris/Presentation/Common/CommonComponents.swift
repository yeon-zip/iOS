//
//  CommonComponents.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

final class CardContainerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.surface
        layer.cornerRadius = AppRadius.medium
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = AppColor.line.cgColor
        AppShadow.applyCard(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ContentSizedCollectionView: UICollectionView {
    var minimumContentHeight: CGFloat = 0 {
        didSet {
            guard minimumContentHeight != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var contentSize: CGSize {
        didSet {
            guard contentSize != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: max(contentSize.height, minimumContentHeight)
        )
    }
}

final class LoadingOverlayView: UIView {
    private let backgroundView = UIVisualEffectView(effect: nil)
    private let indicatorView = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        layer.cornerRadius = AppRadius.medium
        layer.cornerCurve = .continuous
        clipsToBounds = true

        backgroundColor = .clear
        backgroundView.isHidden = true
        indicatorView.hidesWhenStopped = false
        indicatorView.color = AppColor.accent

        addSubviews(backgroundView, indicatorView)
        [backgroundView, indicatorView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        isAccessibilityElement = true
        accessibilityLabel = "로딩 중"
        accessibilityIdentifier = "loadingOverlayView"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLoading(_ isLoading: Bool) {
        isHidden = isLoading == false
        isUserInteractionEnabled = isLoading

        if isLoading {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    }
}

final class IconActionButton: UIButton {
    enum Style {
        case plain
        case soft
    }

    private var currentSymbolName: String
    private var foregroundColor = AppColor.textSecondary
    private let style: Style

    override var intrinsicContentSize: CGSize {
        switch style {
        case .plain:
            return CGSize(width: 32, height: 32)
        case .soft:
            return CGSize(width: 36, height: 36)
        }
    }

    init(symbolName: String, style: Style = .plain, accessibilityLabel: String? = nil) {
        currentSymbolName = symbolName
        self.style = style
        super.init(frame: .zero)
        contentHorizontalAlignment = .center
        contentVerticalAlignment = .center
        isAccessibilityElement = true
        self.accessibilityLabel = accessibilityLabel
        applyConfiguration(symbolName: symbolName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSymbolName(_ symbolName: String) {
        guard currentSymbolName != symbolName else { return }
        currentSymbolName = symbolName
        applyConfiguration(symbolName: symbolName)
    }

    func setForegroundColor(_ color: UIColor) {
        foregroundColor = color
        applyConfiguration(symbolName: currentSymbolName)
    }

    private func applyConfiguration(symbolName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbolName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(
            pointSize: style == .plain ? 15 : 16,
            weight: .semibold
        )
        configuration.baseForegroundColor = foregroundColor
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
        if style == .soft {
            configuration.background.backgroundColor = AppColor.iconSurface
            configuration.background.cornerRadius = 18
        }
        self.configuration = configuration
        accessibilityIdentifier = "iconActionButton.\(symbolName)"
        tintColor = foregroundColor
    }
}

final class SearchInputView: UIControl, UITextFieldDelegate {
    private let containerView = UIView()
    private let textField = UITextField()
    private let searchButton = UIButton(type: .system)
    private let placeholder: String

    var onSubmit: ((String) -> Void)?
    var onTap: (() -> Void)?
    var onTextChanged: ((String) -> Void)?

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var isEditable: Bool = false {
        didSet {
            textField.isUserInteractionEnabled = isEditable
            containerView.isUserInteractionEnabled = isEditable
            isAccessibilityElement = isEditable == false
            accessibilityTraits = isEditable ? [] : [.button]
        }
    }

    init(placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        containerView.backgroundColor = AppColor.chipFill
        containerView.layer.cornerRadius = 16
        containerView.layer.cornerCurve = .continuous
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppColor.line.cgColor
        textField.placeholder = placeholder
        textField.font = AppTypography.body
        textField.textColor = AppColor.textPrimary
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        textField.accessibilityLabel = placeholder
        textField.accessibilityIdentifier = "searchInputView.textField"
        textField.delegate = self
        textField.addTarget(self, action: #selector(handleTextChanged(_:)), for: .editingChanged)

        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "magnifyingglass")
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        configuration.baseForegroundColor = AppColor.textTertiary
        configuration.contentInsets = .zero
        searchButton.configuration = configuration
        searchButton.accessibilityLabel = "검색"
        searchButton.accessibilityIdentifier = "searchInputView.searchButton"
        searchButton.addTarget(self, action: #selector(handleSearchTap), for: .touchUpInside)

        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: self)

        containerView.addSubviews(textField, searchButton)
        textField.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 46),

            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            textField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -AppSpacing.s),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            searchButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),
            searchButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            searchButton.widthAnchor.constraint(equalToConstant: 20),
            searchButton.heightAnchor.constraint(equalToConstant: 20)
        ])

        accessibilityIdentifier = "searchInputView"
        accessibilityLabel = placeholder
        accessibilityTraits = [.button]
        isEditable = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func accessibilityActivate() -> Bool {
        if isEditable == false {
            sendActions(for: .touchUpInside)
            onTap?()
            return true
        }
        return super.accessibilityActivate()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSubmit?(textField.text ?? "")
        textField.resignFirstResponder()
        return true
    }

    @objc private func handleTextChanged(_ sender: UITextField) {
        onTextChanged?(sender.text ?? "")
    }

    @objc private func handleSearchTap() {
        onSubmit?(textField.text ?? "")
        textField.resignFirstResponder()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        guard isEditable == false else { return }
        sendActions(for: .touchUpInside)
        onTap?()
    }
}

final class SearchTriggerButton: UIButton {
    init(placeholder: String) {
        super.init(frame: .zero)

        var configuration = UIButton.Configuration.plain()
        configuration.title = placeholder
        configuration.image = UIImage(systemName: "magnifyingglass")
        configuration.imagePlacement = .trailing
        configuration.imagePadding = AppSpacing.s
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        configuration.baseForegroundColor = AppColor.textSecondary
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: AppSpacing.l,
            bottom: 12,
            trailing: AppSpacing.l
        )
        configuration.background.backgroundColor = AppColor.chipFill
        configuration.background.strokeColor = AppColor.line
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = 16
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppTypography.body
            return outgoing
        }

        self.configuration = configuration
        contentHorizontalAlignment = .fill
        titleLabel?.textAlignment = .left
        semanticContentAttribute = .forceLeftToRight
        layer.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FilterChipGroupView: UIView {
    private let stackView = UIStackView()
    private var buttons: [UIButton] = []
    private var selectedOption: DistanceOption
    private let options: [DistanceOption]

    var onSelectionChanged: ((DistanceOption) -> Void)?

    init(options: [DistanceOption], selected: DistanceOption) {
        self.options = options
        selectedOption = selected
        super.init(frame: .zero)

        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.s
        stackView.distribution = .fillEqually
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinEdges(to: self)

        options.forEach { option in
            let button = UIButton(type: .system)
            button.setTitle(option.rawValue, for: .normal)
            button.titleLabel?.font = AppTypography.caption
            button.layer.cornerRadius = AppRadius.small
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.layer.borderColor = AppColor.line.cgColor
            button.tag = buttons.count
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        updateSelection(selected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSelection(_ option: DistanceOption) {
        selectedOption = option
        for (index, button) in buttons.enumerated() {
            let isSelected = options[index] == option
            button.backgroundColor = isSelected ? AppColor.accentSurface : AppColor.surface
            button.setTitleColor(isSelected ? AppColor.accent : AppColor.textSecondary, for: .normal)
            button.layer.borderWidth = isSelected ? 0 : 1
            button.layer.borderColor = isSelected ? UIColor.clear.cgColor : AppColor.line.cgColor
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        let option = options[sender.tag]
        updateSelection(option)
        onSelectionChanged?(option)
    }
}

final class StatusBadgeView: UIView {
    private let label = UILabel()

    init(content: BadgeContent) {
        super.init(frame: .zero)
        backgroundColor = toneColor(content.tone).background
        layer.cornerRadius = 9
        layer.cornerCurve = .continuous

        label.text = content.title
        label.font = AppTypography.tiny
        label.textColor = toneColor(content.tone).foreground
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func toneColor(_ tone: BadgeContent.Tone) -> (foreground: UIColor, background: UIColor) {
        switch tone {
        case .blue:
            return (AppColor.accent, AppColor.accentSurface)
        case .green:
            return (AppColor.success, AppColor.successSurface)
        case .red:
            return (AppColor.danger, AppColor.dangerSurface)
        case .yellow:
            return (UIColor(hex: 0x9B6608), AppColor.warningSurface)
        case .gray:
            return (AppColor.textSecondary, AppColor.chipFill)
        }
    }
}

final class InlineToggleView: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    var onToggle: ((Bool) -> Void)?

    override var isEnabled: Bool {
        didSet {
            alpha = isEnabled ? 1 : 0.45
            accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
        }
    }

    override var isSelected: Bool {
        didSet {
            iconView.image = UIImage(systemName: isSelected ? "checkmark.square.fill" : "square")
            iconView.tintColor = isSelected ? AppColor.accent : AppColor.textTertiary
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        titleLabel.text = title
        titleLabel.font = AppTypography.caption
        titleLabel.textColor = AppColor.textSecondary

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xs
        stackView.alignment = .center
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinEdges(to: self)
        isSelected = false
        isEnabled = true
        addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func toggleSelection() {
        guard isEnabled else { return }
        isSelected.toggle()
        onToggle?(isSelected)
    }
}

final class SectionHeaderView: UIView {
    private let titleLabel = UILabel()
    private let accessoryContainer = UIView()

    init(title: String, accessoryView: UIView? = nil) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = AppTypography.section
        titleLabel.textColor = AppColor.textPrimary

        addSubviews(titleLabel, accessoryContainer)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        accessoryContainer.translatesAutoresizingMaskIntoConstraints = false

        if let accessoryView {
            accessoryContainer.addSubview(accessoryView)
            accessoryView.translatesAutoresizingMaskIntoConstraints = false
            accessoryView.pinEdges(to: accessoryContainer)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),

            accessoryContainer.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: AppSpacing.m),
            accessoryContainer.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            accessoryContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateTitle(_ title: String) {
        titleLabel.text = title
    }
}

final class NavigationHeaderView: UIView {
    let backButton = IconActionButton(symbolName: "chevron.left", accessibilityLabel: "뒤로가기")
    private let titleLabel = UILabel()
    private let dividerView = UIView()

    init(title: String, showsDivider: Bool = true) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = AppTypography.title
        titleLabel.textColor = AppColor.textPrimary

        dividerView.backgroundColor = AppColor.line
        dividerView.isHidden = showsDivider == false

        addSubviews(backButton, titleLabel, dividerView)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: topAnchor),
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: AppSpacing.s),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            dividerView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: AppSpacing.s),
            dividerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class EmptyStateView: UIView {
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()

    init(title: String, message: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = AppTypography.headline
        titleLabel.textColor = AppColor.textPrimary

        messageLabel.text = message
        messageLabel.font = AppTypography.caption
        messageLabel.textColor = AppColor.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xs
        stackView.alignment = .center

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinEdges(to: self, insets: UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UnderlineSegmentControlView: UIView {
    private let stackView = UIStackView()
    private let indicatorView = UIView()
    private var buttons: [UIButton] = []
    private var indicatorLeadingConstraint: NSLayoutConstraint?
    private var indicatorWidthConstraint: NSLayoutConstraint?

    var onSelectionChanged: ((Int) -> Void)?
    private(set) var selectedIndex: Int = 0

    init(titles: [String]) {
        super.init(frame: .zero)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        addSubviews(stackView, indicatorView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        indicatorView.translatesAutoresizingMaskIntoConstraints = false

        titles.enumerated().forEach { index, title in
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppTypography.subheadline
            button.setTitleColor(AppColor.textSecondary, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        indicatorView.backgroundColor = AppColor.accent
        indicatorView.layer.cornerRadius = 1

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: 2)
        ])

        setSelectedIndex(0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard buttons.isEmpty == false else { return }
        let buttonWidth = bounds.width / CGFloat(buttons.count)
        indicatorLeadingConstraint?.isActive = false
        indicatorWidthConstraint?.isActive = false
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: buttonWidth * CGFloat(selectedIndex))
        indicatorWidthConstraint = indicatorView.widthAnchor.constraint(equalToConstant: buttonWidth)
        indicatorLeadingConstraint?.isActive = true
        indicatorWidthConstraint?.isActive = true
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        selectedIndex = index
        buttons.enumerated().forEach { idx, button in
            let isSelected = idx == index
            button.setTitleColor(isSelected ? AppColor.textPrimary : AppColor.textSecondary, for: .normal)
        }

        setNeedsLayout()
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    func updateTitles(_ titles: [String]) {
        guard titles.count == buttons.count else { return }
        for (index, title) in titles.enumerated() {
            buttons[index].setTitle(title, for: .normal)
        }
    }

    @objc private func handleTap(_ sender: UIButton) {
        setSelectedIndex(sender.tag, animated: true)
        onSelectionChanged?(sender.tag)
    }
}

final class CollectionSectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "CollectionSectionHeaderView"

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = AppTypography.section
        titleLabel.textColor = AppColor.textPrimary
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
