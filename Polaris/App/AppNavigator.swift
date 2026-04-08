//
//  AppNavigator.swift
//  Polaris
//
//  Created by Codex on 4/8/26.
//

import UIKit

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
        case .search:
            navigationController.pushViewController(makeSearch(), animated: true)
        case .likes:
            navigationController.pushViewController(makeLikes(), animated: true)
        case .alerts:
            navigationController.pushViewController(makeAlerts(), animated: true)
        case .profile:
            navigationController.pushViewController(makeProfile(), animated: true)
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
        let viewModel = HomeViewModel(libraryRepository: dependencies.libraryRepository)
        return HomeViewController(viewModel: viewModel, navigator: self)
    }

    private func makeSearch() -> SearchResultsViewController {
        let viewModel = SearchResultsViewModel(
            searchRepository: dependencies.searchRepository,
            libraryRepository: dependencies.libraryRepository
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
