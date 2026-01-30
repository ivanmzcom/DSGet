//
//  RecentFoldersService.swift
//  DSGet
//
//  Service to manage recently used destination folders.
//

import Foundation

/// Service that manages recently used destination folders for task creation.
@MainActor
final class RecentFoldersService: RecentFoldersManaging {
    static let shared = RecentFoldersService()

    private let userDefaultsKey = "recentDestinationFolders"
    private let maxRecentFolders = 10
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Returns the list of recent folders (most recent first).
    var recentFolders: [String] {
        userDefaults.stringArray(forKey: userDefaultsKey) ?? []
    }

    /// Adds a folder path to the recent list.
    /// - Parameter path: The folder path to add.
    func addRecentFolder(_ path: String) {
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

        userDefaults.set(folders, forKey: userDefaultsKey)
    }

    /// Clears all recent folders.
    func clearRecentFolders() {
        userDefaults.removeObject(forKey: userDefaultsKey)
    }
}
