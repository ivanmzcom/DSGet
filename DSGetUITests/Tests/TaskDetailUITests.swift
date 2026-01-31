import XCTest

final class TaskDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()
        // Downloads is the default section — auto-navigates on compact
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

        // Navigate back and switch to feeds
        app.navigateToSection("sidebar.feeds")

        let feedListPage = FeedListPage(app: app)
        XCTAssertTrue(feedListPage.list.waitForExistence(timeout: 5))
    }
}
