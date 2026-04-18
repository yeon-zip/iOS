//
//  AppNavigator.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

protocol LocationSelectionHandling: AnyObject {
    func applySelectedLocation(_ suggestion: AddressSuggestion)
}

@MainActor
final class AppNavigator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.viewControllers = [makeHome()]
    }

    func handle(_ route: AppRoute, from source: UIViewController) {
        switch route {
        case let .search(currentLocation, currentDistance):
            navigationController.pushViewController(
                makeSearch(currentLocation: currentLocation, currentDistance: currentDistance),
                animated: true
            )
        case .likes:
            navigationController.pushViewController(makeLikes(), animated: true)
        case .alerts:
            navigationController.pushViewController(makeAlerts(), animated: true)
        case .profile:
            navigationController.pushViewController(makeProfile(), animated: true)
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

    private func makeHome() -> HomeViewController {
        let homeViewModel = HomeViewModel(libraryRepository: dependencies.libraryRepository)
        let searchViewModel = SearchResultsViewModel(
            searchRepository: dependencies.searchRepository,
            libraryRepository: dependencies.libraryRepository,
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

    private func makeSearch(currentLocation: AddressSuggestion, currentDistance: DistanceOption) -> SearchResultsViewController {
        let viewModel = SearchResultsViewModel(
            searchRepository: dependencies.searchRepository,
            libraryRepository: dependencies.libraryRepository,
            currentLocation: currentLocation,
            currentDistance: currentDistance
        )
        return SearchResultsViewController(viewModel: viewModel, navigator: self)
    }

    private func makeLikes() -> LikeViewController {
        let viewModel = LikeViewModel(favoritesRepository: dependencies.favoritesRepository)
        return LikeViewController(viewModel: viewModel, navigator: self)
    }

    private func makeAlerts() -> AlarmViewController {
        let viewModel = AlarmViewModel(alertsRepository: dependencies.alertsRepository)
        return AlarmViewController(viewModel: viewModel, navigator: self)
    }

    private func makeLibraryDetail(id: String) -> LibraryDetailViewController {
        let viewModel = LibraryDetailViewModel(libraryID: id, libraryRepository: dependencies.libraryRepository)
        return LibraryDetailViewController(viewModel: viewModel, navigator: self)
    }

    private func makeBookDetail(id: String) -> BookDetailViewController {
        let viewModel = BookDetailViewModel(bookID: id, bookRepository: dependencies.bookRepository)
        return BookDetailViewController(viewModel: viewModel)
    }

    private func makeProfile() -> ProfileViewController {
        let viewModel = ProfileViewModel(profileRepository: dependencies.profileRepository)
        return ProfileViewController(viewModel: viewModel, navigator: self)
    }
}
