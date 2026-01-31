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

    /// Finds a sidebar row by accessibility identifier.
    /// SwiftUI List rows may be exposed as cells, buttons, or other types.
    func sidebarItem(_ identifier: String) -> XCUIElement {
        for query in [cells, buttons, staticTexts] {
            let element = query[identifier]
            if element.exists { return element }
        }
        return descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Resolves a hittable sidebar element by trying multiple XCUITest types.
    private func findHittableSidebarElement(_ identifier: String) -> XCUIElement? {
        for query in [cells, buttons, staticTexts] {
            let element = query[identifier]
            if element.exists, element.isHittable { return element }
        }
        let fallback = descendants(matching: .any).matching(identifier: identifier).firstMatch
        if fallback.exists, fallback.isHittable { return fallback }
        return nil
    }

    /// Navigates to a sidebar section. On compact, this may require going back first.
    func navigateToSection(_ identifier: String, timeout: TimeInterval = 5) {
        // First try: sidebar item is already visible
        if let element = findHittableSidebarElement(identifier) {
            element.tap()
            return
        }

        // Wait briefly for sidebar to appear
        _ = cells[identifier].waitForExistence(timeout: 1)
            || buttons[identifier].waitForExistence(timeout: 1)
        if let element = findHittableSidebarElement(identifier) {
            element.tap()
            return
        }

        // On compact, go back to sidebar
        for _ in 0..<5 {
            let backButton = navigationBars.buttons.element(boundBy: 0)
            guard backButton.exists, backButton.isHittable else { break }
            backButton.tap()
            // Wait for sidebar to appear after back navigation
            _ = cells[identifier].waitForExistence(timeout: 2)
                || buttons[identifier].waitForExistence(timeout: 1)
            if let element = findHittableSidebarElement(identifier) {
                element.tap()
                return
            }
        }
    }
}
