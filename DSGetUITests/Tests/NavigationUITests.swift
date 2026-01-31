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
        // Go back to sidebar from auto-navigated downloads
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()

        let downloads = app.sidebarItem("sidebar.downloads")
        let feeds = app.sidebarItem("sidebar.feeds")
        let settings = app.sidebarItem("sidebar.settings")

        XCTAssertTrue(downloads.waitForExistence(timeout: 5))
        XCTAssertTrue(feeds.exists)
        XCTAssertTrue(settings.exists)
    }

    func testSwitchToFeedsSection() {
        app.navigateToSection("sidebar.feeds")

        let feedListPage = FeedListPage(app: app)
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
    }

    func testSwitchToSettingsSection() {
        app.navigateToSection("sidebar.settings")

        let settingsPage = SettingsPage(app: app)
        XCTAssertTrue(settingsPage.logoutButton.waitForExistence(timeout: 5))
    }

    func testSwitchBackToDownloadsSection() {
        // Go to settings first
        app.navigateToSection("sidebar.settings")

        // Switch back to downloads
        app.navigateToSection("sidebar.downloads")

        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testAddTaskSheetFromDownloads() {
        // Downloads is auto-selected
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.addButton.waitForExistence(timeout: 5))
        taskListPage.addButton.tap()

        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.urlField.waitForExistence(timeout: 5))

        addTaskPage.cancelButton.tap()
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }
}
