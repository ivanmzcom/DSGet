//
//  RecentFoldersService.swift
//  DSGet
//
//  Service to manage recently used destination folders.
//

import Foundation

/// Service that manages recently used destination folders for task creation.
enum RecentFoldersService {

    private static let userDefaultsKey = "recentDestinationFolders"
    private static let maxRecentFolders = 10

    /// Returns the list of recent folders (most recent first).
    static var recentFolders: [String] {
        UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
    }

    /// Adds a folder path to the recent list.
    /// - Parameter path: The folder path to add.
    static func addRecentFolder(_ path: String) {
        guard !path.isEmpty else { return }

        var folders = recentFolders

        // Remove if already exists (will be re-added at the top)
        folders.removeAll { $0 == path }

        // Insert at the beginning
        folders.insert(path, at: 0)

        // Keep only the last N folders
        if folders.count > maxRecentFolders {
            folders = Array(folders.prefix(maxRecentFolders))
        }

        UserDefaults.standard.set(folders, forKey: userDefaultsKey)
    }

    /// Clears all recent folders.
    static func clearRecentFolders() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
