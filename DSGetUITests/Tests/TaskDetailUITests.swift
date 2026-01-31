import XCTest

final class TaskDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()

        // Navigate to downloads section
        let downloads = app.cells["sidebar.downloads"]
        XCTAssertTrue(downloads.waitForExistence(timeout: 5))
        downloads.tap()
    }

    func testTaskDetailAppearsOnTap() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))

        app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].tap()

        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 5))
    }

    func testNavigateBackFromDetail() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].tap()

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
    }

    func testSectionSwitchingFromDetail() {
        let taskListPage = TaskListPage(app: app)
        XCTAssertTrue(taskListPage.list.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].waitForExistence(timeout: 10))
        app.staticTexts["Ubuntu 24.04 LTS Desktop.iso"].tap()

        // Navigate back to sidebar and switch to feeds
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        let feeds = app.cells["sidebar.feeds"]
        XCTAssertTrue(feeds.waitForExistence(timeout: 5))
        feeds.tap()

        let feedListPage = FeedListPage(app: app)
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
    }
}
