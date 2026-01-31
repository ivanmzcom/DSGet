import XCTest

final class FolderPickerUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()

        // Navigate to downloads section
        let downloads = app.cells["sidebar.downloads"]
        XCTAssertTrue(downloads.waitForExistence(timeout: 5))
        downloads.tap()

        // Open add task sheet
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.addButton.waitForExistence(timeout: 5))
        taskListPage.addButton.tap()
    }

    func testAddTaskSheetAppears() {
        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.urlField.waitForExistence(timeout: 5))
    }

    func testModePickerVisible() {
        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.modePicker.waitForExistence(timeout: 5))
    }

    func testCancelDismissesAddTask() {
        let addTaskPage = AddTaskPage(app: app)
        XCTAssertTrue(addTaskPage.cancelButton.waitForExistence(timeout: 5))
        addTaskPage.cancelButton.tap()

        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }
}
