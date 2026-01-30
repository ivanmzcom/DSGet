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
}
