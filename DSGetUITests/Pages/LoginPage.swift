//
//  LoginPage.swift
//  DSGetUITests
//

import XCTest

struct LoginPage {
    let app: XCUIApplication

    var serverNameField: XCUIElement { app.textFields["login.serverName"] }
    var hostField: XCUIElement { app.textFields["login.host"] }
    var portField: XCUIElement { app.textFields["login.port"] }
    var httpsToggle: XCUIElement { app.switches["login.httpsToggle"] }
    var usernameField: XCUIElement { app.textFields["login.username"] }
    var passwordField: XCUIElement { app.secureTextFields["login.password"] }
    var otpField: XCUIElement { app.secureTextFields["login.otp"] }
    var loginButton: XCUIElement { app.buttons["login.loginButton"] }

    func fillForm(host: String, username: String, password: String) {
        hostField.tap()
        hostField.typeText(host)
        usernameField.tap()
        usernameField.typeText(username)
        passwordField.tap()
        passwordField.typeText(password)
    }
}
