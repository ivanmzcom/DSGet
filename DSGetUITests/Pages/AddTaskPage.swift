//
//  AddTaskPage.swift
//  DSGetUITests
//

import XCTest

struct AddTaskPage {
    let app: XCUIApplication

    var urlField: XCUIElement { app.textFields["addTask.urlField"] }
    var createButton: XCUIElement { app.buttons["addTask.createButton"] }
    var cancelButton: XCUIElement { app.buttons["addTask.cancelButton"] }
    var modePicker: XCUIElement { app.segmentedControls["addTask.modePicker"] }
}
