//
//  AddTaskUITests.swift
//  DSGetUITests
//

import XCTest

final class AddTaskUITests: XCTestCase {
    private var app: XCUIApplication!
    private var addTaskPage: AddTaskPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()
        // Downloads is the default section — auto-navigates on compact

        // Open add task sheet
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.addButton.waitForExistence(timeout: 5))
        taskListPage.addButton.tap()

        addTaskPage = AddTaskPage(app: app)
    }

    func testURLModeFieldPresent() {
        XCTAssertTrue(addTaskPage.urlField.waitForExistence(timeout: 5))
    }

    func testCreateButtonDisabledWhenEmpty() {
        XCTAssertTrue(addTaskPage.createButton.waitForExistence(timeout: 5))
        XCTAssertFalse(addTaskPage.createButton.isEnabled)
    }

    func testCancelDismissesSheet() {
        XCTAssertTrue(addTaskPage.cancelButton.waitForExistence(timeout: 5))
        addTaskPage.cancelButton.tap()

        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testModePickerPresent() {
        XCTAssertTrue(addTaskPage.modePicker.waitForExistence(timeout: 5))
    }

    func testModePickerHasSegments() {
        XCTAssertTrue(addTaskPage.modePicker.waitForExistence(timeout: 5))
        XCTAssertTrue(addTaskPage.modePicker.buttons["URL"].exists)
        XCTAssertTrue(addTaskPage.modePicker.buttons[".torrent"].exists)
    }

    func testSwitchToFileMode() {
        XCTAssertTrue(addTaskPage.modePicker.waitForExistence(timeout: 5))
        addTaskPage.modePicker.buttons[".torrent"].tap()

        XCTAssertTrue(addTaskPage.modePicker.buttons[".torrent"].isSelected)
    }
}
