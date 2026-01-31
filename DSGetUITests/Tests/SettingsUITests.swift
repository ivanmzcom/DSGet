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
        app.navigateToSection("sidebar.settings")
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

        let loginPage = LoginPage(app: app)
        XCTAssertTrue(loginPage.hostField.waitForExistence(timeout: 10))
    }

    func testVersionInfoExists() {
        XCTAssertTrue(settingsPage.serverName.waitForExistence(timeout: 5))
        XCTAssertEqual(settingsPage.serverName.label, "My NAS")
    }
}
