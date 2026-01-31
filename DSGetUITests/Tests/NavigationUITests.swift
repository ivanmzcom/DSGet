//
//  NavigationUITests.swift
//  DSGetUITests
//

import XCTest

final class NavigationUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()
    }

    func testSidebarHasThreeSections() {
        let downloads = app.cells["sidebar.downloads"]
        let feeds = app.cells["sidebar.feeds"]
        let settings = app.cells["sidebar.settings"]

        XCTAssertTrue(downloads.waitForExistence(timeout: 5))
        XCTAssertTrue(feeds.exists)
        XCTAssertTrue(settings.exists)
    }

    func testSwitchToFeedsSection() {
        let feeds = app.cells["sidebar.feeds"]
        XCTAssertTrue(feeds.waitForExistence(timeout: 5))
        feeds.tap()

        let feedListPage = FeedListPage(app: app)
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
    }

    func testSwitchToSettingsSection() {
        let settings = app.cells["sidebar.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        let settingsPage = SettingsPage(app: app)
        XCTAssertTrue(settingsPage.logoutButton.waitForExistence(timeout: 5))
    }

    func testSwitchBackToDownloadsSection() {
        // Go to settings first
        let settings = app.cells["sidebar.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        // Navigate back to sidebar and switch to downloads
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let downloads = app.cells["sidebar.downloads"]
        XCTAssertTrue(downloads.waitForExistence(timeout: 5))
        downloads.tap()

        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testAddTaskSheetFromDownloads() {
        // Navigate to downloads content
        let downloads = app.cells["sidebar.downloads"]
        XCTAssertTrue(downloads.waitForExistence(timeout: 5))
        downloads.tap()

        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.addButton.waitForExistence(timeout: 5))
        taskListPage.addButton.tap()

        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.urlField.waitForExistence(timeout: 5))

        addTaskPage.cancelButton.tap()
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }
}
