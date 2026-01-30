//
//  WidgetDataSyncProtocol.swift
//  DSGet
//
//  Protocol for widget data synchronization service.
//

import Foundation
import DSGetCore

/// Protocol for synchronizing download data with App Groups for widget access.
@MainActor
protocol WidgetDataSyncProtocol {
    func syncDownloads(_ tasks: [DownloadTask])
    func setConnectionError()
    func lastUpdateDate() -> Date?
    func hasCachedData() -> Bool
    func isRecentSync() -> Bool
}
