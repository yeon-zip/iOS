//
//  PolarisUITests.swift
//  PolarisUITests
//
//  Created by 손유나 on 3/27/26.
//

import XCTest

final class PolarisUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-useMockData")
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testHomeToSearchToBookDetailSheet() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        let searchInput = app.buttons["home.searchInput"]
        XCTAssertTrue(searchInput.waitForExistence(timeout: 3))
        searchInput.tap()
        XCTAssertTrue(app.otherElements["searchScreen"].waitForExistence(timeout: 3))

        let firstBookCell = app.collectionViews["search.bookCollection"].cells["bookCarouselCell"].firstMatch
        XCTAssertTrue(firstBookCell.waitForExistence(timeout: 3))
        firstBookCell.tap()

        XCTAssertFalse(app.otherElements["bookDetailSheet"].exists)

        let detailButton = firstBookCell.buttons["bookCarouselCell.detailButton"]
        XCTAssertTrue(detailButton.waitForExistence(timeout: 3))
        detailButton.tap()
        XCTAssertTrue(app.otherElements["bookDetailSheet"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeNavigationToLikes() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        app.buttons["home.likesButton"].tap()
        XCTAssertTrue(app.otherElements["likesScreen"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeNavigationToAlerts() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        app.buttons["home.alertsButton"].tap()
        XCTAssertTrue(app.otherElements["alertsScreen"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeNavigationToProfile() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        app.buttons["home.profileButton"].tap()
        XCTAssertTrue(app.otherElements["profileScreen"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeNavigationToLibraryDetail() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        let firstLibraryCell = app.collectionViews.cells["libraryCardCell"].firstMatch
        XCTAssertTrue(firstLibraryCell.waitForExistence(timeout: 3))
        firstLibraryCell.tap()
        XCTAssertTrue(app.otherElements["libraryDetailScreen"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testHomeOpensLocationPicker() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        let locationButton = app.buttons["home.locationButton"]
        XCTAssertTrue(locationButton.waitForExistence(timeout: 3))
        locationButton.tap()
        XCTAssertTrue(app.otherElements["locationPickerScreen"].waitForExistence(timeout: 3))
    }
}
