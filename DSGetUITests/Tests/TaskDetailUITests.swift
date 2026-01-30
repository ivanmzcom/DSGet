import XCTest

final class TaskDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()
    }

    func testTaskDetailAppearsOnTap() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))

        app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].tap()

        // Task detail should show the title
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 5))
    }

    func testNavigateBackFromDetail() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].tap()

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testTabSwitchingFromDetail() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].tap()

        // Switch to feeds tab
        let feedsTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(feedsTab.waitForExistence(timeout: 5))
        feedsTab.tap()

        let feedListPage = FeedListPage(app: app)
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
    }
}
