//
//  ProfileViewController.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

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
            self?.contentView.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }
}

private final class ProfileView: UIView {
    let headerView = NavigationHeaderView(title: "프로필", showsDivider: false)
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let profileCard = CardContainerView()
    private let avatarView = ProfileAvatarView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let errorLabel = UILabel()
    private let loadingOverlayView = LoadingOverlayView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background

        contentStack.axis = .vertical
        contentStack.spacing = AppSpacing.l

        nameLabel.font = AppTypography.title
        nameLabel.textColor = AppColor.textPrimary
        nameLabel.numberOfLines = 2

        emailLabel.font = AppTypography.body
        emailLabel.textColor = AppColor.textSecondary
        emailLabel.numberOfLines = 2

        errorLabel.font = AppTypography.body
        errorLabel.textColor = AppColor.textSecondary
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let headerStack = UIStackView(arrangedSubviews: [avatarView, nameStack])
        headerStack.axis = .horizontal
        headerStack.spacing = AppSpacing.xl
        headerStack.alignment = .center

        profileCard.addSubview(headerStack)
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        profileCard.isHidden = true

        contentStack.addArrangedSubview(profileCard)
        contentStack.addArrangedSubview(errorLabel)

        addSubviews(headerView, scrollView, loadingOverlayView)
        scrollView.addSubview(contentStack)
        [headerView, scrollView, contentStack, loadingOverlayView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.s),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: AppSpacing.xl),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: AppSpacing.xxl),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -AppSpacing.xxl),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -AppSpacing.xxxl),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(AppSpacing.xxl * 2)),

            headerStack.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: AppSpacing.xxl),
            headerStack.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: AppSpacing.xxl),
            headerStack.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -AppSpacing.xxl),
            headerStack.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -AppSpacing.xxl),

            avatarView.widthAnchor.constraint(equalToConstant: 72),
            avatarView.heightAnchor.constraint(equalToConstant: 72),

            loadingOverlayView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            loadingOverlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingOverlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingOverlayView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        accessibilityIdentifier = "profileScreen"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(_ state: ProfileViewModel.State) {
        loadingOverlayView.setLoading(state.isLoading)

        if let profile = state.profile {
            profileCard.isHidden = false
            avatarView.configure(profile: profile)
            nameLabel.text = profile.nickname
            emailLabel.text = profile.email
        } else {
            profileCard.isHidden = true
        }

        errorLabel.text = state.errorMessage
        errorLabel.isHidden = state.errorMessage == nil
    }

    private var nameStack: UIStackView {
        let stackView = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        stackView.axis = .vertical
        stackView.spacing = AppSpacing.xs
        return stackView
    }
}

private final class ProfileAvatarView: UIView {
    private static let imageCache = NSCache<NSURL, UIImage>()

    private let imageView = UIImageView()
    private let initialLabel = UILabel()
    private var imageTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.accentSurface
        layer.cornerRadius = 36
        layer.cornerCurve = .continuous
        clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.isHidden = true

        initialLabel.font = AppTypography.title
        initialLabel.textColor = AppColor.accent
        initialLabel.textAlignment = .center

        addSubviews(imageView, initialLabel)
        [imageView, initialLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        imageView.pinEdges(to: self)
        initialLabel.pinEdges(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        imageTask?.cancel()
    }

    func configure(profile: UserProfile) {
        imageTask?.cancel()
        imageView.image = nil
        imageView.isHidden = true
        initialLabel.isHidden = false
        initialLabel.text = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines).first.map(String.init) ?? "북"

        guard let imageURL = profile.profileImageURL else { return }
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
                // Initial fallback remains visible if the profile image cannot be loaded.
            }
        }
    }

    private func applyLoadedImage(_ image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        initialLabel.isHidden = true
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("프로필") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)

    return ProfileViewController(
        viewModel: ProfileViewModel(profileRepository: dependencies.profileRepository),
        navigator: navigator
    )
}
#endif
