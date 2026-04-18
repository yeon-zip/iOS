//
//  LoginViewController.swift
//  Polaris
//
//  Created by Codex on 4/26/26.
//

import AuthenticationServices
import UIKit
#if canImport(SwiftUI)
import SwiftUI
#endif

final class LoginViewController: BaseViewController {
    private let viewModel: LoginViewModel
    private weak var navigator: AppNavigator?
    private let contentView = LoginView()
    private var webAuthSession: ASWebAuthenticationSession?

    init(viewModel: LoginViewModel, navigator: AppNavigator) {
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
        render(viewModel.state)
    }

    private func bind() {
        contentView.kakaoLoginButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            Task {
                guard let request = await self.viewModel.prepareKakaoLogin() else { return }
                self.startWebAuthentication(request: request)
            }
        }, for: .touchUpInside)

        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }

        viewModel.onRoute = { [weak self] route in
            guard let self, let navigator = self.navigator else { return }
            navigator.handle(route, from: self)
        }
    }

    private func render(_ state: LoginViewModel.State) {
        contentView.kakaoLoginButton.isEnabled = state.isLoading == false
        contentView.loadingView.setLoading(state.isLoading)
        contentView.errorLabel.text = state.errorMessage
        contentView.errorLabel.isHidden = state.errorMessage == nil
    }

    private func startWebAuthentication(request: AuthLoginRequest) {
        webAuthSession?.cancel()

        let session = ASWebAuthenticationSession(
            url: request.url,
            callbackURLScheme: request.callbackScheme
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.webAuthSession = nil

                if let callbackURL {
                    Task { await self.viewModel.completeLogin(callbackURL: callbackURL) }
                    return
                }

                if let authenticationError = error as? ASWebAuthenticationSessionError,
                   authenticationError.code == .canceledLogin {
                    self.viewModel.didCancelExternalLogin()
                } else {
                    self.viewModel.didFailExternalLogin()
                }
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        webAuthSession = session

        if session.start() == false {
            webAuthSession = nil
            viewModel.didFailExternalLogin()
        }
    }
}

extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window ?? ASPresentationAnchor()
    }
}

private final class LoginView: UIView {
    let kakaoLoginButton = UIButton(type: .system)
    let errorLabel = UILabel()
    let loadingView = LoadingOverlayView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColor.background

        let titleLabel = UILabel()
        let subtitleLabel = UILabel()
        let stackView = UIStackView()

        titleLabel.text = "북극성"
        titleLabel.font = AppTypography.hero
        titleLabel.textColor = AppColor.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "내 주변 도서관과 원하는 책을 빠르게 찾고, 관심 도서는 한곳에 모아보세요."
        subtitleLabel.font = AppTypography.body
        subtitleLabel.textColor = AppColor.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        var kakaoConfiguration = UIButton.Configuration.filled()
        kakaoConfiguration.title = "카카오로 로그인"
        kakaoConfiguration.image = UIImage(systemName: "message.fill")
        kakaoConfiguration.imagePadding = AppSpacing.s
        kakaoConfiguration.baseForegroundColor = UIColor(hex: 0x191919)
        kakaoConfiguration.background.backgroundColor = UIColor(hex: 0xFEE500)
        kakaoConfiguration.background.cornerRadius = AppRadius.medium
        kakaoConfiguration.contentInsets = NSDirectionalEdgeInsets(
            top: 14,
            leading: AppSpacing.xl,
            bottom: 14,
            trailing: AppSpacing.xl
        )
        kakaoConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = AppTypography.subheadline
            return outgoing
        }
        kakaoLoginButton.configuration = kakaoConfiguration
        kakaoLoginButton.accessibilityIdentifier = "login.kakaoButton"

        errorLabel.font = AppTypography.caption
        errorLabel.textColor = AppColor.danger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true
        errorLabel.accessibilityIdentifier = "login.errorLabel"

        stackView.axis = .vertical
        stackView.spacing = AppSpacing.l
        stackView.alignment = .fill
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.setCustomSpacing(AppSpacing.xxl, after: subtitleLabel)
        stackView.addArrangedSubview(kakaoLoginButton)
        stackView.addArrangedSubview(errorLabel)

        addSubviews(stackView, loadingView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: AppSpacing.xxl),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -AppSpacing.xxl),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -AppSpacing.xxl),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor, constant: AppSpacing.xxl),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.bottomAnchor, constant: -AppSpacing.xxl),

            kakaoLoginButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),

            loadingView.topAnchor.constraint(equalTo: topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            loadingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        accessibilityIdentifier = "loginScreen"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG && canImport(SwiftUI)
#Preview("로그인") {
    let dependencies = AppDependencies.mock
    let navigationController = UINavigationController()
    let navigator = AppNavigator(navigationController: navigationController, dependencies: dependencies)

    return LoginViewController(
        viewModel: LoginViewModel(authRepository: dependencies.authRepository),
        navigator: navigator
    )
}
#endif
