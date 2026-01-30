//
//  RecentFoldersManaging.swift
//  DSGet
//
//  Protocol for managing recently used destination folders.
//

import Foundation

/// Protocol for managing recently used destination folders.
@MainActor
protocol RecentFoldersManaging {
    var recentFolders: [String] { get }
    func addRecentFolder(_ path: String)
    func clearRecentFolders()
}
