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
    func testHomeSearchPushesToSearchScreenAndOpensBookDetailSheet() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        let searchField = app.textFields["searchInputView.textField"].firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("아몬드")
        app.buttons["searchInputView.searchButton"].firstMatch.tap()

        XCTAssertTrue(app.otherElements["searchScreen"].waitForExistence(timeout: 3))

        let firstBookCell = app.collectionViews["search.bookCollection"].cells["bookCarouselCell"].firstMatch
        XCTAssertTrue(firstBookCell.waitForExistence(timeout: 3))
        let detailButton = firstBookCell.buttons["bookCarouselCell.detailButton"]
        XCTAssertTrue(detailButton.waitForExistence(timeout: 3))
        detailButton.tap()
        XCTAssertTrue(app.otherElements["bookDetailSheet"].waitForExistence(timeout: 3))
    }

    @MainActor
    func testSearchScreenCanDismissWithEdgeSwipe() throws {
        XCTAssertTrue(app.otherElements["homeScreen"].waitForExistence(timeout: 3))

        let searchField = app.textFields["searchInputView.textField"].firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("아몬드")
        app.buttons["searchInputView.searchButton"].firstMatch.tap()

        let searchScreen = app.otherElements["searchScreen"]
        XCTAssertTrue(searchScreen.waitForExistence(timeout: 3))
        XCTAssertTrue(app.collectionViews["search.bookCollection"].waitForExistence(timeout: 3))

        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: end)

        let homeLocationButton = app.buttons["home.locationButton"]
        let homeVisible = NSPredicate(format: "hittable == true")
        expectation(for: homeVisible, evaluatedWith: homeLocationButton)
        waitForExpectations(timeout: 3)
        XCTAssertTrue(homeLocationButton.isHittable)
        XCTAssertFalse(app.buttons["search.backButton"].isHittable)
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
