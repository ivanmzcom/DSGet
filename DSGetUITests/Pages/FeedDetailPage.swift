import XCTest

struct FeedDetailPage {
    let app: XCUIApplication

    var itemList: XCUIElement { app.collectionViews.firstMatch }
    var refreshButton: XCUIElement { app.buttons["feedDetail.refreshButton"] }
    var firstItem: XCUIElement { app.staticTexts["Ubuntu 24.04 Released"] }
}
