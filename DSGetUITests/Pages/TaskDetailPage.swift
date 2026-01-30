import XCTest

struct TaskDetailPage {
    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars.firstMatch }
    var pauseResumeButton: XCUIElement { app.buttons["taskDetail.pauseResumeButton"] }
    var deleteButton: XCUIElement { app.buttons["taskDetail.deleteButton"] }
    var deleteConfirmButton: XCUIElement { app.buttons["Delete"] }
    var statusText: XCUIElement { app.staticTexts["taskDetail.status"] }
}
