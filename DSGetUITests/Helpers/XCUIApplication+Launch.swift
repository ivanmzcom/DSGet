//
//  XCUIApplication+Launch.swift
//  DSGetUITests
//

import XCTest

extension XCUIApplication {
    /// Launches the app configured for UI testing with stub services.
    static func launchForTesting() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        return app
    }

    /// Launches the app in logged-out state for login testing.
    static func launchLoggedOut() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--uitesting-logged-out"]
        app.launch()
        return app
    }

    /// Finds a sidebar item by accessibility identifier.
    /// Works regardless of the underlying element type (cell, button, etc.).
    func sidebarItem(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier]
    }

    /// Navigates to a sidebar section. On compact, this may require going back first.
    func navigateToSection(_ identifier: String, timeout: TimeInterval = 5) {
        let item = sidebarItem(identifier)
        if item.waitForExistence(timeout: 2) {
            item.tap()
            return
        }
        // On compact, we may need to go back to sidebar first
        while navigationBars.buttons.element(boundBy: 0).exists {
            navigationBars.buttons.element(boundBy: 0).tap()
            if item.waitForExistence(timeout: 1) {
                item.tap()
                return
            }
        }
    }
}
