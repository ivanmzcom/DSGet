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

    func testTabBarHasThreeTabs() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        XCTAssertEqual(tabBar.buttons.count, 3)
    }

    func testSwitchToFeedsTab() {
        let feedsTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(feedsTab.waitForExistence(timeout: 5))
        feedsTab.tap()

        let feedListPage = FeedListPage(app: app)
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
    }

    func testSwitchToSettingsTab() {
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        let settingsPage = SettingsPage(app: app)
        XCTAssertTrue(settingsPage.logoutButton.waitForExistence(timeout: 5))
    }

    func testSwitchBackToDownloadsTab() {
        // Go to settings first
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        // Switch back to downloads
        let downloadsTab = app.tabBars.buttons.element(boundBy: 0)
        downloadsTab.tap()

        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testAddTaskSheetFromTabBar() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.addButton.waitForExistence(timeout: 5))
        taskListPage.addButton.tap()

        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.urlField.waitForExistence(timeout: 5))

        addTaskPage.cancelButton.tap()
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testTabBarPersistsAcrossNavigation() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))

        // Switch through all tabs
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertEqual(tabBar.buttons.count, 3)

        app.tabBars.buttons.element(boundBy: 2).tap()
        XCTAssertEqual(tabBar.buttons.count, 3)

        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertEqual(tabBar.buttons.count, 3)
    }
}
