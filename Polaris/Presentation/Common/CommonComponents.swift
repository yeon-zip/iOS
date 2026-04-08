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
        AppShadow.applyCard(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class IconActionButton: UIButton {
    private var currentSymbolName: String

    override var intrinsicContentSize: CGSize {
        CGSize(width: 44, height: 44)
    }

    init(symbolName: String, accessibilityLabel: String? = nil) {
        currentSymbolName = symbolName
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

    private func applyConfiguration(symbolName: String) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbolName)
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        configuration.baseForegroundColor = AppColor.textPrimary
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        self.configuration = configuration
        accessibilityIdentifier = "iconActionButton.\(symbolName)"
        tintColor = AppColor.textPrimary
    }
}

final class SearchInputView: UIControl, UITextFieldDelegate {
    private let containerView = CardContainerView()
    private let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let textField = UITextField()
    private let placeholder: String

    var onSubmit: ((String) -> Void)?
    var onTap: (() -> Void)?

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var isEditable: Bool = false {
        didSet {
            textField.isUserInteractionEnabled = isEditable
            containerView.isUserInteractionEnabled = isEditable
            accessibilityTraits = isEditable ? [.searchField] : [.button]
        }
    }

    init(placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        iconView.tintColor = AppColor.textTertiary
        textField.placeholder = placeholder
        textField.font = AppTypography.caption
        textField.textColor = AppColor.textPrimary
        textField.returnKeyType = .search
        textField.delegate = self

        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.pinEdges(to: self)

        containerView.addSubviews(textField, iconView)
        textField.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 48),

            textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: AppSpacing.l),
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            iconView.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: AppSpacing.s),
            iconView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -AppSpacing.l),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18)
        ])

        accessibilityIdentifier = "searchInputView"
        accessibilityLabel = placeholder
        accessibilityTraits = [.button]
        isAccessibilityElement = true
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
        configuration.baseForegroundColor = AppColor.textTertiary
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: AppSpacing.m,
            leading: AppSpacing.l,
            bottom: AppSpacing.m,
            trailing: AppSpacing.l
        )
        configuration.background.backgroundColor = AppColor.surface
        configuration.background.cornerRadius = AppRadius.medium
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppTypography.caption
            return outgoing
        }

        self.configuration = configuration
        contentHorizontalAlignment = .fill
        titleLabel?.textAlignment = .left
        semanticContentAttribute = .forceRightToLeft
        layer.cornerCurve = .continuous
        AppShadow.applyCard(to: self)
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
            button.backgroundColor = isSelected ? AppColor.textPrimary : AppColor.surface
            button.setTitleColor(isSelected ? .white : AppColor.textPrimary, for: .normal)
            button.layer.borderWidth = isSelected ? 0 : 1
            button.layer.borderColor = AppColor.line.cgColor
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
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous

        label.text = content.title
        label.font = AppTypography.tiny
        label.textColor = toneColor(content.tone).foreground
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func toneColor(_ tone: BadgeContent.Tone) -> (foreground: UIColor, background: UIColor) {
        switch tone {
        case .blue:
            return (AppColor.accent, UIColor(hex: 0xEAF2FF))
        case .green:
            return (AppColor.success, UIColor(hex: 0xEAF7ED))
        case .red:
            return (AppColor.danger, UIColor(hex: 0xFDEBEC))
        case .yellow:
            return (UIColor(hex: 0xA16A00), UIColor(hex: 0xFFF4CC))
        case .gray:
            return (AppColor.textSecondary, UIColor(hex: 0xF2F4F6))
        }
    }
}

final class InlineToggleView: UIControl {
    private let iconView = UIImageView()
    private let titleLabel = UILabel()

    var onToggle: ((Bool) -> Void)?

    override var isSelected: Bool {
        didSet {
            iconView.image = UIImage(systemName: isSelected ? "checkmark.square.fill" : "square")
            iconView.tintColor = isSelected ? AppColor.accent : AppColor.textTertiary
        }
    }

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = AppTypography.tiny
        titleLabel.textColor = AppColor.textTertiary

        let stackView = UIStackView(arrangedSubviews: [iconView, titleLabel])
        stackView.axis = .horizontal
        stackView.spacing = AppSpacing.xs
        stackView.alignment = .center
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinEdges(to: self)
        isSelected = false
        addTarget(self, action: #selector(toggleSelection), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func toggleSelection() {
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
        titleLabel.font = AppTypography.headline
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
}

final class NavigationHeaderView: UIView {
    let backButton = IconActionButton(symbolName: "arrow.left", accessibilityLabel: "뒤로가기")
    private let titleLabel = UILabel()
    private let dividerView = UIView()

    init(title: String, showsDivider: Bool = true) {
        super.init(frame: .zero)
        titleLabel.text = title
        titleLabel.font = AppTypography.hero
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
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: AppSpacing.m),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            dividerView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: AppSpacing.m),
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
        stackView.spacing = AppSpacing.s
        stackView.alignment = .center

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.pinEdges(to: self, insets: UIEdgeInsets(top: 32, left: 16, bottom: 32, right: 16))
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
            button.titleLabel?.font = AppTypography.body
            button.setTitleColor(AppColor.textTertiary, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(handleTap(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
            buttons.append(button)
        }

        indicatorView.backgroundColor = AppColor.textPrimary
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
            button.setTitleColor(isSelected ? AppColor.textPrimary : AppColor.textTertiary, for: .normal)
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
        titleLabel.font = AppTypography.headline
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
