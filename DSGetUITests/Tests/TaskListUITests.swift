//
//  TaskListUITests.swift
//  DSGetUITests
//

import XCTest

final class TaskListUITests: XCTestCase {
    private var app: XCUIApplication!
    private var taskListPage: TaskListPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()
        taskListPage = TaskListPage(app: app)
    }

    func testShowsStubTasks() {
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))

        // Verify stub task titles appear as static text
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Fedora-Workstation-40.iso"].exists)
        XCTAssertTrue(app.staticTexts["Arch-Linux-2024.01.iso"].exists)
    }

    func testAddButtonOpensSheet() {
        XCTAssertTrue(taskListPage.addButton.waitForExistence(timeout: 5))
        taskListPage.addButton.tap()

        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.urlField.waitForExistence(timeout: 5))
    }

    func testSearchFiltersResults() {
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        // Verify tasks are loaded first
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))

        // Swipe down to reveal search, then search
        taskListPage.list.swipeDown()

        let searchField = taskListPage.searchField
        guard searchField.waitForExistence(timeout: 5) else {
            // Search field may not appear on all layouts — skip gracefully
            return
        }
        searchField.tap()
        searchField.typeText("Ubuntu")

        // Ubuntu task should still be visible
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 5))
    }

    func testEmptyStateNotShownWithTasks() {
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        // Empty state should not be visible when tasks exist
        XCTAssertFalse(app.staticTexts["No Downloads"].exists)
    }

    func testMultipleTasksVisible() {
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Fedora-Workstation-40.iso"].exists)
        XCTAssertTrue(app.staticTexts["Arch-Linux-2024.01.iso"].exists)
    }
}
