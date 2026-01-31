//
//  LoginUITests.swift
//  DSGetUITests
//

import XCTest

final class LoginUITests: XCTestCase {
    private var app: XCUIApplication!
    private var loginPage: LoginPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchLoggedOut()
        loginPage = LoginPage(app: app)
    }

    func testLoginFieldsArePresent() {
        XCTAssertTrue(loginPage.hostField.waitForExistence(timeout: 5))
        XCTAssertTrue(loginPage.usernameField.exists)
        XCTAssertTrue(loginPage.passwordField.exists)
        XCTAssertTrue(loginPage.loginButton.exists)
        XCTAssertTrue(loginPage.httpsToggle.exists)
    }

    func testLoginButtonDisabledWhenFieldsEmpty() {
        XCTAssertTrue(loginPage.loginButton.waitForExistence(timeout: 5))
        XCTAssertFalse(loginPage.loginButton.isEnabled)
    }

    func testSuccessfulLoginNavigatesToMain() {
        XCTAssertTrue(loginPage.hostField.waitForExistence(timeout: 5))
        loginPage.fillForm(host: "192.168.1.1", username: "admin", password: "password")

        XCTAssertTrue(loginPage.loginButton.isEnabled)
        loginPage.loginButton.tap()

        // After login, the sidebar should appear
        let downloads = app.cells["sidebar.downloads"]
        XCTAssertTrue(downloads.waitForExistence(timeout: 10))
    }

    func testLoginButtonDisabledWithPartialForm() {
        XCTAssertTrue(loginPage.hostField.waitForExistence(timeout: 5))

        loginPage.hostField.tap()
        loginPage.hostField.typeText("192.168.1.1")

        // Only host filled, button should still be disabled
        XCTAssertFalse(loginPage.loginButton.isEnabled)
    }

    func testHTTPSToggleExists() {
        XCTAssertTrue(loginPage.httpsToggle.waitForExistence(timeout: 5))
    }

    func testOTPFieldNotVisibleByDefault() {
        XCTAssertTrue(loginPage.hostField.waitForExistence(timeout: 5))
        // OTP field should not be visible until needed
        // It may be hidden by default
        XCTAssertFalse(loginPage.otpField.exists)
    }
}
