import UIKit

protocol LocationSelectionHandling: AnyObject {
    func applySelectedLocation(_ suggestion: AddressSuggestion)
}

@MainActor
final class AppNavigator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies
    private var startupTask: Task<Void, Never>?

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        navigationController.setNavigationBarHidden(true, animated: false)
        startupTask?.cancel()

        let startupController = makeStartup()
        navigationController.viewControllers = [startupController]

        startupTask = Task { [weak self, weak startupController] in
            await self?.showInitialScreen(replacing: startupController)
        }
    }

    func handle(_ route: AppRoute, from source: UIViewController) {
        switch route {
        case .home:
            showHome(animated: true)
        case let .search(currentLocation, currentDistance, initialQuery):
            navigationController.pushViewController(
                makeSearch(
                    currentLocation: currentLocation,
                    currentDistance: currentDistance,
                    initialQuery: initialQuery
                ),
                animated: true
            )
        case let .bookSearch(query):
            navigationController.pushViewController(
                makeSearch(
                    currentLocation: defaultSearchLocation,
                    currentDistance: .twoKm,
                    initialQuery: query
                ),
                animated: true
            )
        case .likes:
            navigationController.pushViewController(makeLikes(), animated: true)
        case .alerts:
            navigationController.pushViewController(makeAlerts(), animated: true)
        case .profile:
            navigationController.pushViewController(makeProfile(), animated: true)
        case .login:
            guard !(navigationController.topViewController is LoginViewController) else { return }
            showLogin(animated: true)
        case let .locationPicker(currentLocation):
            guard let locationHandler = source as? LocationSelectionHandling else { return }
            let controller = makeLocationPicker(currentLocation: currentLocation) { [weak locationHandler] address in
                locationHandler?.applySelectedLocation(address)
            }
            controller.modalPresentationStyle = .pageSheet
            if let sheet = controller.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = AppRadius.large
            }
            source.present(controller, animated: true)
        case let .libraryDetail(id):
            navigationController.pushViewController(makeLibraryDetail(id: id), animated: true)
        case let .bookDetail(id):
            let controller = makeBookDetail(id: id)
            controller.modalPresentationStyle = .pageSheet
            if let sheet = controller.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = AppRadius.large
            }
            source.present(controller, animated: true)
        case .back:
            navigationController.popViewController(animated: true)
        }
    }

    private func showInitialScreen(replacing startupController: UIViewController?) async {
        let restoredSession = await dependencies.authRepository.restoreSession()

        guard Task.isCancelled == false,
              let startupController,
              navigationController.viewControllers.first === startupController else {
            return
        }

        startupTask = nil

        if restoredSession != nil {
            showHome(animated: false)
        } else {
            showLogin(animated: false)
        }
    }

    private func showHome(animated: Bool) {
        AppRuntime.shared.pushNotificationCoordinator.activate()
        navigationController.setViewControllers([makeHome()], animated: canAnimateNavigationChange(animated))
    }

    private func showLogin(animated: Bool) {
        navigationController.setViewControllers([makeLogin()], animated: canAnimateNavigationChange(animated))
    }

    private func canAnimateNavigationChange(_ requestedAnimation: Bool) -> Bool {
        requestedAnimation && navigationController.view.window != nil
    }

    private func makeStartup() -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = AppColor.background
        return controller
    }

    private func makeHome() -> HomeViewController {
        let homeViewModel = HomeViewModel(
            libraryRepository: dependencies.libraryRepository,
            favoritesRepository: dependencies.favoritesRepository
        )
        let searchViewModel = SearchResultsViewModel(
            searchRepository: dependencies.searchRepository,
            libraryRepository: dependencies.libraryRepository,
            favoritesRepository: dependencies.favoritesRepository,
            alertsRepository: dependencies.alertsRepository,
            currentLocation: homeViewModel.state.selectedLocation,
            currentDistance: homeViewModel.state.selectedDistance
        )
        return HomeViewController(viewModel: homeViewModel, searchViewModel: searchViewModel, navigator: self)
    }

    private func makeLocationPicker(
        currentLocation: AddressSuggestion,
        onSelection: @escaping (AddressSuggestion) -> Void
    ) -> LocationPickerViewController {
        let viewModel = LocationPickerViewModel(
            currentLocation: currentLocation,
            locationAddressService: dependencies.locationAddressService
        )
        return LocationPickerViewController(viewModel: viewModel, onSelection: onSelection)
    }

    private func makeSearch(
        currentLocation: AddressSuggestion,
        currentDistance: DistanceOption,
        initialQuery: String?
    ) -> SearchResultsViewController {
        let viewModel = SearchResultsViewModel(
            searchRepository: dependencies.searchRepository,
            libraryRepository: dependencies.libraryRepository,
            favoritesRepository: dependencies.favoritesRepository,
            alertsRepository: dependencies.alertsRepository,
            currentLocation: currentLocation,
            currentDistance: currentDistance,
            initialQuery: initialQuery
        )
        return SearchResultsViewController(viewModel: viewModel, navigator: self)
    }

    private func makeLikes() -> LikeViewController {
        let viewModel = LikeViewModel(favoritesRepository: dependencies.favoritesRepository)
        return LikeViewController(viewModel: viewModel, navigator: self)
    }

    private func makeAlerts() -> AlarmViewController {
        let viewModel = AlarmViewModel(alertsRepository: MockAlertsRepository())
        return AlarmViewController(viewModel: viewModel, navigator: self)
    }

    private func makeLibraryDetail(id: String) -> LibraryDetailViewController {
        let viewModel = LibraryDetailViewModel(libraryID: id, libraryRepository: dependencies.libraryRepository)
        return LibraryDetailViewController(viewModel: viewModel, navigator: self)
    }

    private func makeBookDetail(id: String) -> BookDetailViewController {
        let viewModel = BookDetailViewModel(
            bookID: id,
            bookRepository: dependencies.bookRepository,
            favoritesRepository: dependencies.favoritesRepository,
            bookVoteRepository: dependencies.bookVoteRepository
        )
        return BookDetailViewController(viewModel: viewModel)
    }

    private func makeProfile() -> ProfileViewController {
        let viewModel = ProfileViewModel(profileRepository: dependencies.profileRepository)
        return ProfileViewController(viewModel: viewModel, navigator: self)
    }

    private func makeLogin() -> LoginViewController {
        let viewModel = LoginViewModel(authRepository: dependencies.authRepository)
        return LoginViewController(viewModel: viewModel, navigator: self)
    }

    private var defaultSearchLocation: AddressSuggestion {
        AddressSuggestion.defaultLocation
    }
}
