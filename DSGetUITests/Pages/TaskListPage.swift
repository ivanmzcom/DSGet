//
//  TaskListPage.swift
//  DSGetUITests
//

import XCTest

struct TaskListPage {
    let app: XCUIApplication

    var list: XCUIElement { app.collectionViews["taskList.list"] }
    var addButton: XCUIElement { app.buttons["taskList.addButton"] }
    var searchField: XCUIElement { app.searchFields.firstMatch }

    func taskRow(id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "taskList.taskRow.\(id)").firstMatch
    }

    var visibleTaskTexts: XCUIElementQuery {
        app.staticTexts
    }
}
