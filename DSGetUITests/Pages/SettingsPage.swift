//
//  SettingsPage.swift
//  DSGetUITests
//

import XCTest

struct SettingsPage {
    let app: XCUIApplication

    var serverName: XCUIElement { app.staticTexts["settings.serverName"] }
    var logoutButton: XCUIElement { app.buttons["settings.logoutButton"] }
}
