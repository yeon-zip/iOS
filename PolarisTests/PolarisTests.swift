//
//  PolarisTests.swift
//  PolarisTests
//
//  Created by 손유나 on 3/27/26.
//

import Foundation
import Testing
@testable import Polaris

private struct StubLocationAddressService: LocationAddressService {
    let currentAddress: AddressSuggestion
    let resolvedAddress: AddressSuggestion

    func requestCurrentAddress() async throws -> AddressSuggestion {
        currentAddress
    }

    func resolveAddress(roadAddress: String, detailText: String) async throws -> AddressSuggestion {
        AddressSuggestion(
            id: resolvedAddress.id,
            roadAddress: roadAddress,
            detailText: detailText,
            latitude: resolvedAddress.latitude,
            longitude: resolvedAddress.longitude
        )
    }
}

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

        await viewModel.didUpdateLocation(
            AddressSuggestion(
                id: "test-location",
                roadAddress: "서울특별시 강남구 테헤란로 133",
                detailText: "역삼동",
                latitude: 37.4995,
                longitude: 127.0311
            )
        ).value
        #expect(viewModel.state.selectedLocation.roadAddress == "서울특별시 강남구 테헤란로 133")
        #expect(viewModel.state.libraries.first?.title == "강남 도서관")
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
        #expect(viewModel.state.sections[.available]?.first?.libraryName == "강남 도서관")
    }

    @Test func locationPickerViewModelAcceptsPostcodeSelection() async throws {
        let locationService = StubLocationAddressService(
            currentAddress: AddressSuggestion(
                id: "current-location",
                roadAddress: "경상북도 구미시 대학로 61",
                detailText: "현재 위치",
                latitude: 36.1450,
                longitude: 128.3937
            ),
            resolvedAddress: AddressSuggestion(
                id: "resolved-address",
                roadAddress: "경기도 용인시 기흥구 서천동로21번길 21",
                detailText: "서천마을 중앙상가",
                latitude: 37.2410,
                longitude: 127.0724
            )
        )
        let viewModel = LocationPickerViewModel(
            currentLocation: locationService.currentAddress,
            locationAddressService: locationService
        )

        var selectedSuggestion: AddressSuggestion?
        viewModel.onAddressSelected = { suggestion in
            selectedSuggestion = suggestion
        }

        viewModel.didSelectPostcode(
            PostcodeSelection(
                roadAddress: "경기도 용인시 기흥구 서천동로21번길 21",
                jibunAddress: "경기도 용인시 기흥구 서천동 123-4",
                buildingName: "서천마을 중앙상가",
                legalDongName: "서천동",
                zoneCode: "17112"
            )
        )
        try await Task.sleep(for: .milliseconds(20))

        viewModel.didTapConfirm()

        #expect(viewModel.state.selectedAddress?.roadAddress == "경기도 용인시 기흥구 서천동로21번길 21")
        #expect(selectedSuggestion?.detailText == "서천마을 중앙상가 · 서천동 · 경기도 용인시 기흥구 서천동 123-4")
    }
}
