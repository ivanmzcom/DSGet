//
//  FeedListUITests.swift
//  DSGetUITests
//

import XCTest

final class FeedListUITests: XCTestCase {
    private var app: XCUIApplication!
    private var feedListPage: FeedListPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()

        // Navigate to feeds tab
        let feedsTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(feedsTab.waitForExistence(timeout: 5))
        feedsTab.tap()

        feedListPage = FeedListPage(app: app)
    }

    func testShowsStubFeeds() {
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))

        // Verify stub feed titles appear
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Open Source Software"].exists)
    }

    func testFeedTitlesDisplayed() {
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Open Source Software"].exists)
    }

    func testFeedTapNavigatesToDetail() {
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))

        app.staticTexts["Linux ISOs"].tap()

        // Feed detail should show items
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 Released"].waitForExistence(timeout: 10))
    }

    func testMultipleFeedsVisible() {
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Open Source Software"].exists)
    }
}
