import XCTest

final class FeedDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = .launchForTesting()

        // Navigate to feeds section
        let feeds = app.cells["sidebar.feeds"]
        XCTAssertTrue(feeds.waitForExistence(timeout: 5))
        feeds.tap()
    }

    func testFeedDetailAppearsOnTap() {
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))
        app.staticTexts["Linux ISOs"].tap()

        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 Released"].waitForExistence(timeout: 10))
    }

    func testFeedDetailShowsItems() {
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))
        app.staticTexts["Linux ISOs"].tap()

        let feedDetailPage = FeedDetailPage(app: app)
        XCTAssertTrue(feedDetailPage.firstItem.waitForExistence(timeout: 10))
    }

    func testNavigateBackFromFeedDetail() {
        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 10))
        app.staticTexts["Linux ISOs"].tap()

        XCTAssertTrue(app.staticTexts["Ubuntu 24.04 Released"].waitForExistence(timeout: 10))

        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.staticTexts["Linux ISOs"].waitForExistence(timeout: 5))
    }
}
