//
//  AppConstants.swift
//  DSGet
//
//  Centralized constants for the application.
//

import Foundation

// MARK: - AppConstants

enum AppConstants {
    // MARK: - App Group

    enum AppGroup {
        static let identifier = "group.com.ivanmz.DSGet"
    }

    // MARK: - Storage Keys

    enum StorageKeys {
        static let showActiveDownloadBadge = "showActiveDownloadBadge"
        static let favoriteFeedsData = "favoriteFeedsData"
    }

    // MARK: - Limits

    enum Limits {
        /// Maximum number of recent destinations to store.
        static let maxRecentDestinations = 10

        /// Maximum search polls before stopping.
        static let maxSearchPolls = 30

        /// Default page size for pagination.
        static let defaultPageSize = 50

        /// Large page size for search results.
        static let searchPageSize = 100
    }

    // MARK: - Time Intervals

    enum TimeIntervals {
        /// Search polling interval in seconds.
        static let searchPollInterval: TimeInterval = 2.0

        /// Initial search delay in seconds.
        static let searchInitialDelay: TimeInterval = 1.0

        /// Duration for "recently updated" check (1 hour).
        static let recentUpdateThreshold: TimeInterval = 3600

        /// Default filter date range (30 days).
        static let defaultFilterDays = 30
    }

    // MARK: - Size Thresholds (in bytes)

    enum SizeThresholds {
        /// 100 MB in bytes.
        static let small: Int64 = 100 * 1024 * 1024

        /// 1 GB in bytes.
        static let medium: Int64 = 1024 * 1024 * 1024

        /// 10 GB in bytes.
        static let large: Int64 = 10 * 1024 * 1024 * 1024
    }

    // MARK: - URL Schemes

    enum URLSchemes {
        static let magnet = "magnet"
        static let dsget = "dsget"
        static let torrentExtension = "torrent"
    }

    // MARK: - Deep Link Hosts

    enum DeepLinkHosts {
        static let add = "add"
        static let settings = "settings"
    }

    // MARK: - API Defaults

    enum APIDefaults {
        static let defaultPort: Int = 5000
        static let defaultHTTPSPort: Int = 5001
    }
}
