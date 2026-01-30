//
//  FeedListPage.swift
//  DSGetUITests
//

import XCTest

struct FeedListPage {
    let app: XCUIApplication

    var list: XCUIElement { app.collectionViews["feedList.list"] }

    func feedRow(id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "feedList.feedRow.\(id)").firstMatch
    }
}
