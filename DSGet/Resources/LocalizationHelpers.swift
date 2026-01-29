//
//  LocalizationHelpers.swift
//  DSGet
//
//  Helper extensions for localized strings with format arguments.
//

import Foundation

// MARK: - String Extension for Localization

extension String {
    /// Returns a localized string with the given key and optional arguments.
    /// This is a convenience wrapper around NSLocalizedString.
    /// - Parameters:
    ///   - key: The localization key
    ///   - comment: A comment for translators
    ///   - args: Optional format arguments
    /// - Returns: The localized string
    static func localized(_ key: String, comment: String = "", _ args: CVarArg...) -> String {
        if args.isEmpty {
            return NSLocalizedString(key, comment: comment)
        } else {
            let format = NSLocalizedString(key, comment: comment)
            return String(format: format, arguments: args)
        }
    }
}

// MARK: - Empty State Helpers

struct EmptyStateText {
    static let noDownloadsTitle = "empty.downloads.title"
    static let noDownloadsDescription = "empty.downloads.description"
    static let noDownloadsAction = "empty.downloads.action"

    static let noFeedsTitle = "empty.feeds.title"
    static let noFeedsDescription = "empty.feeds.description"
    static let noFeedsAction = "empty.feeds.action"

    static let searchPromptTitle = "empty.search.title"
    static let searchPromptDescription = "empty.search.description"

    static let offlineTitle = "empty.offline.title"
    static let offlineDescription = "empty.offline.description"
    static let offlineAction = "empty.offline.action"

    static let errorTitle = "empty.error.title"
    static let errorAction = "empty.error.action"

    static let notConnectedTitle = "empty.notConnected.title"
    static let notConnectedDescription = "empty.notConnected.description"
    static let notConnectedAction = "empty.notConnected.action"

    static let loadingTitle = "empty.loading.title"
    static let loadingSubtitle = "empty.loading.subtitle"

    static let noTasksTitle = "empty.noTasks.title"
    static let noTasksDescription = "empty.noTasks.description"

    static let noFolders = "empty.noFolders"
}

// MARK: - Error Helpers

struct ErrorText {
    static let title = "error.title"
    static let unknown = "error.unknown"
    static let network = "error.network"
    static let invalidURL = "error.invalidURL"
    static let noDownloadURL = "error.noDownloadURL"
}

// MARK: - General Helpers

struct GeneralText {
    static let ok = "general.ok"
    static let cancel = "general.cancel"
    static let delete = "general.delete"
    static let close = "general.close"
    static let create = "general.create"
    static let copy = "general.copy"
    static let share = "general.share"
    static let select = "general.select"
}

// MARK: - Offline Mode Helpers

struct OfflineText {
    static let mode = "offline.mode"
    static let cachedData = "offline.cachedData"
}
