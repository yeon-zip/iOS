//
//  PolarisTests.swift
//  PolarisTests
//
//  Created by 손유나 on 3/27/26.
//

import Foundation
import Testing
@testable import Polaris

@MainActor
struct PolarisTests {

    @Test func homeViewModelAppliesDistanceAndClosedFilter() async throws {
        let viewModel = HomeViewModel(libraryRepository: MockLibraryRepository())

        await viewModel.load()
        #expect(viewModel.state.libraries.count == 2)

        await viewModel.didSelectDistance(.threeKm).value
        #expect(viewModel.state.libraries.count == 4)

        await viewModel.didToggleExcludeClosed(true).value
        #expect(viewModel.state.libraries.count == 3)
    }

    @Test func searchViewModelReflectsUnavailableToggle() async throws {
        let viewModel = SearchResultsViewModel(
            searchRepository: MockSearchRepository(),
            libraryRepository: MockLibraryRepository()
        )

        await viewModel.load()
        #expect(viewModel.state.books.count == 3)
        #expect(viewModel.state.libraries.count == 4)
        #expect(viewModel.state.selectedBookID == nil)

        await viewModel.didSelectBook(id: "book-arond-2").value
        #expect(viewModel.state.selectedBookID == "book-arond-2")
        #expect(viewModel.state.books.first(where: { $0.id == "book-arond-2" })?.isSelected == true)
        #expect(viewModel.state.libraries.count == 2)

        await viewModel.didToggleExcludeUnavailable(true).value
        #expect(viewModel.state.libraries.count == 1)
    }

    @Test func likeViewModelSwitchesTabsWithoutLosingData() async throws {
        let viewModel = LikeViewModel(favoritesRepository: MockFavoritesRepository())

        await viewModel.load()
        #expect(viewModel.state.selectedTab == .books)
        #expect(viewModel.state.books.count == 2)
        #expect(viewModel.state.libraries.count == 2)

        viewModel.didSelectTab(index: FavoriteTab.libraries.rawValue)
        #expect(viewModel.state.selectedTab == .libraries)
        #expect(viewModel.state.libraries.first?.title == "강남 도서관")
    }

    @Test func alarmViewModelGroupsItemsBySection() async throws {
        let viewModel = AlarmViewModel(alertsRepository: MockAlertsRepository())

        await viewModel.load()
        #expect(viewModel.state.sections[.available]?.count == 1)
        #expect(viewModel.state.sections[.waiting]?.count == 1)
    }
}
