//
//  SpotlightIndexing.swift
//  DSGet
//
//  Protocol for Spotlight search indexing.
//

import Foundation
import DSGetCore

/// Protocol for indexing download tasks in Spotlight search.
@MainActor
protocol SpotlightIndexing {
    func indexTasks(_ tasks: [DownloadTask])
    func indexTask(_ task: DownloadTask)
    func removeTask(_ task: DownloadTask)
    func removeAllItems()
    func updateTasks(_ tasks: [DownloadTask])
}
