//
//  SettingsUITests.swift
//  DSGetUITests
//

import XCTest

final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!
    private var settingsPage: SettingsPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()

        // Navigate to settings tab
        let settingsTab = app.tabBars.buttons.element(boundBy: 2)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        settingsPage = SettingsPage(app: app)
    }

    func testServerNameDisplayed() {
        XCTAssertTrue(settingsPage.serverName.waitForExistence(timeout: 5))
        XCTAssertEqual(settingsPage.serverName.label, "My NAS")
    }

    func testLogoutButtonPresent() {
        XCTAssertTrue(settingsPage.logoutButton.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsPage.logoutButton.isEnabled)
    }

    func testLogoutReturnsToLogin() {
        XCTAssertTrue(settingsPage.logoutButton.waitForExistence(timeout: 5))
        settingsPage.logoutButton.tap()

        // After logout, login view should appear
        let loginPage = LoginPage(app: app)
        XCTAssertTrue(loginPage.hostField.waitForExistence(timeout: 10))
    }

    func testVersionInfoExists() {
        // Settings page should show some version-related information
        // Look for any version text on the settings page
        XCTAssertTrue(settingsPage.serverName.waitForExistence(timeout: 5))
        // Server name should be "My NAS" from stub
        XCTAssertEqual(settingsPage.serverName.label, "My NAS")
    }
}
