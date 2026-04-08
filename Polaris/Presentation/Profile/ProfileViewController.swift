//
//  ProfileViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

final class ProfileViewController: BaseViewController {
    private let viewModel: ProfileViewModel
    private weak var navigator: AppNavigator?
    private let contentView = ProfileView()

    init(viewModel: ProfileViewModel, navigator: AppNavigator) {
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

    private func render(_ state: ProfileViewModel.State) {
        guard let profile = state.profile else { return }
        contentView.nameLabel.text = profile.name
        contentView.subtitleLabel.text = profile.subtitle
        contentView.locationLabel.text = profile.location
        contentView.headlineLabel.text = profile.headline
    }
}

private final class ProfileView: UIView {
    let headerView = NavigationHeaderView(title: "프로필", showsDivider: false)
    let nameLabel = UILabel()
    let subtitleLabel = UILabel()
    let locationLabel = UILabel()
    let headlineLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background

        let profileCard = CardContainerView()
        let avatarView = UIView()
        let infoStack = UIStackView()
        let comingSoonCard = CardContainerView()
        let comingSoonLabel = UILabel()

        avatarView.backgroundColor = AppColor.elevated
        avatarView.layer.cornerRadius = 38
        avatarView.layer.cornerCurve = .continuous

        nameLabel.font = AppTypography.hero
        nameLabel.textColor = AppColor.textPrimary
        subtitleLabel.font = AppTypography.body
        subtitleLabel.textColor = AppColor.textSecondary
        locationLabel.font = AppTypography.caption
        locationLabel.textColor = AppColor.textTertiary
        headlineLabel.font = AppTypography.body
        headlineLabel.textColor = AppColor.textPrimary
        headlineLabel.numberOfLines = 0

        infoStack.axis = .vertical
        infoStack.spacing = AppSpacing.xs
        infoStack.addArrangedSubview(nameLabel)
        infoStack.addArrangedSubview(subtitleLabel)
        infoStack.addArrangedSubview(locationLabel)

        comingSoonLabel.text = "계정 설정과 활동 로그는 API 연동 단계에서 확장됩니다."
        comingSoonLabel.font = AppTypography.body
        comingSoonLabel.textColor = AppColor.textSecondary
        comingSoonLabel.numberOfLines = 0

        addSubviews(headerView, profileCard, comingSoonCard)
        [headerView, profileCard, comingSoonCard].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        profileCard.addSubviews(avatarView, infoStack, headlineLabel)
        [avatarView, infoStack, headlineLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        comingSoonCard.addSubview(comingSoonLabel)
        comingSoonLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.xl),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            profileCard.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: AppSpacing.xxl),
            profileCard.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            profileCard.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),

            avatarView.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: AppSpacing.l),
            avatarView.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: AppSpacing.l),
            avatarView.widthAnchor.constraint(equalToConstant: 76),
            avatarView.heightAnchor.constraint(equalToConstant: 76),

            infoStack.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: AppSpacing.xs),
            infoStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: AppSpacing.l),
            infoStack.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -AppSpacing.l),

            headlineLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: AppSpacing.l),
            headlineLabel.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            headlineLabel.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -AppSpacing.l),
            headlineLabel.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -AppSpacing.l),

            comingSoonCard.topAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: AppSpacing.l),
            comingSoonCard.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor),
            comingSoonCard.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor),

            comingSoonLabel.topAnchor.constraint(equalTo: comingSoonCard.topAnchor, constant: AppSpacing.l),
            comingSoonLabel.leadingAnchor.constraint(equalTo: comingSoonCard.leadingAnchor, constant: AppSpacing.l),
            comingSoonLabel.trailingAnchor.constraint(equalTo: comingSoonCard.trailingAnchor, constant: -AppSpacing.l),
            comingSoonLabel.bottomAnchor.constraint(equalTo: comingSoonCard.bottomAnchor, constant: -AppSpacing.l)
        ])

        accessibilityIdentifier = "profileScreen"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
