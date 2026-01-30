//
//  StubServices.swift
//  DSGet
//
//  Stub service implementations for UI testing.
//

#if DEBUG

import Foundation
import DSGetCore
import UIKit

// MARK: - Stub Task Service

final class StubTaskService: TaskServiceProtocol, @unchecked Sendable {
    func getTasks(forceRefresh: Bool) async throws -> TasksResult {
        TasksResult(tasks: [
            DownloadTask(
                id: TaskID("task-1"),
                title: "Ubuntu 24.04 LTS Desktop.iso",
                size: ByteSize(bytes: 4_700_000_000),
                status: .downloading,
                type: .bt,
                username: "admin",
                transfer: TaskTransferInfo(
                    downloaded: ByteSize(bytes: 2_350_000_000),
                    uploaded: ByteSize(bytes: 100_000_000),
                    downloadSpeed: ByteSize(bytes: 5_242_880),
                    uploadSpeed: ByteSize(bytes: 524_288)
                )
            ),
            DownloadTask(
                id: TaskID("task-2"),
                title: "Fedora-Workstation-40.iso",
                size: ByteSize(bytes: 2_000_000_000),
                status: .finished,
                type: .bt,
                username: "admin",
                transfer: TaskTransferInfo(
                    downloaded: ByteSize(bytes: 2_000_000_000),
                    uploaded: ByteSize(bytes: 0),
                    downloadSpeed: ByteSize(bytes: 0),
                    uploadSpeed: ByteSize(bytes: 0)
                )
            ),
            DownloadTask(
                id: TaskID("task-3"),
                title: "Arch-Linux-2024.01.iso",
                size: ByteSize(bytes: 900_000_000),
                status: .paused,
                type: .bt,
                username: "admin",
                transfer: TaskTransferInfo(
                    downloaded: ByteSize(bytes: 450_000_000),
                    uploaded: ByteSize(bytes: 0),
                    downloadSpeed: ByteSize(bytes: 0),
                    uploadSpeed: ByteSize(bytes: 0)
                )
            ),
        ], isFromCache: false)
    }

    func createTask(request: CreateTaskRequest) async throws {}
    func pauseTasks(ids: [TaskID]) async throws {}
    func resumeTasks(ids: [TaskID]) async throws {}
    func deleteTasks(ids: [TaskID]) async throws {}
    func editTaskDestination(ids: [TaskID], destination: String) async throws {}
}

// MARK: - Stub Feed Service

final class StubFeedService: FeedServiceProtocol, @unchecked Sendable {
    func getFeeds(forceRefresh: Bool) async throws -> FeedsResult {
        FeedsResult(feeds: [
            RSSFeed(
                id: FeedID("feed-1"),
                title: "Linux ISOs",
                url: URL(string: "https://example.com/feed1"),
                lastUpdate: Date()
            ),
            RSSFeed(
                id: FeedID("feed-2"),
                title: "Open Source Software",
                url: URL(string: "https://example.com/feed2"),
                lastUpdate: Date().addingTimeInterval(-3600)
            ),
        ], isFromCache: false)
    }

    func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem> {
        PaginatedResult(items: [
            RSSFeedItem(
                id: FeedItemID("item-1"),
                title: "Ubuntu 24.04 Released",
                downloadURL: URL(string: "https://example.com/download1"),
                externalURL: nil,
                size: "4.7 GB",
                publishedDate: Date(),
                isNew: true
            ),
        ], total: 1)
    }

    func refreshFeed(id: FeedID) async throws {}
}

// MARK: - Stub Auth Service

final class StubAuthService: AuthServiceProtocol, @unchecked Sendable {
    private let loggedOut: Bool

    init(loggedOut: Bool = false) {
        self.loggedOut = loggedOut
    }

    private let stubSession = Session(
        sessionID: "stub-session",
        serverConfiguration: ServerConfiguration(host: "192.168.1.100", port: 5001, useHTTPS: true)
    )

    private let stubServer = Server(
        name: "My NAS",
        configuration: ServerConfiguration(host: "192.168.1.100", port: 5001, useHTTPS: true)
    )

    func login(request: LoginRequest) async throws -> Session { stubSession }
    func logout() async throws {}

    func validateSession() async throws -> Session? {
        loggedOut ? nil : stubSession
    }

    func getStoredSession() async throws -> Session? {
        loggedOut ? nil : stubSession
    }

    func getCurrentSession() throws -> Session? {
        loggedOut ? nil : stubSession
    }

    func isLoggedIn() async -> Bool { !loggedOut }

    func refreshSession() async throws -> Session { stubSession }

    func getServer() async throws -> Server? { stubServer }
    func saveServer(_ server: Server, credentials: Credentials) async throws {}
    func removeServer() async throws {}
    func hasServer() async -> Bool { true }
    func getCredentials() async throws -> Credentials { Credentials(username: "admin", password: "pass") }
}

// MARK: - Stub Connectivity Service

final class StubConnectivityService: ConnectivityServiceProtocol, @unchecked Sendable {
    var isConnected: Bool { true }
    var connectionType: ConnectionType { .wifi }
    func waitForConnection(timeout: TimeInterval) async -> Bool { true }
}

// MARK: - Stub File Service

final class StubFileService: FileServiceProtocol, @unchecked Sendable {
    func getShares() async throws -> [FileSystemItem] {
        [
            FileSystemItem(name: "downloads", path: "/volume1/downloads", isDirectory: true),
            FileSystemItem(name: "media", path: "/volume1/media", isDirectory: true),
        ]
    }

    func getFolderContents(path: String) async throws -> [FileSystemItem] {
        [
            FileSystemItem(name: "torrents", path: "\(path)/torrents", isDirectory: true),
        ]
    }

    func createFolder(parentPath: String, name: String) async throws {}
}

// MARK: - Stub Widget Data Sync

final class StubWidgetDataSync: WidgetDataSyncProtocol {
    func syncDownloads(_ tasks: [DownloadTask]) {}
    func setConnectionError() {}
    func lastUpdateDate() -> Date? { Date() }
    func hasCachedData() -> Bool { true }
    func isRecentSync() -> Bool { true }
}

// MARK: - Stub Spotlight Indexer

final class StubSpotlightIndexer: SpotlightIndexing {
    func indexTasks(_ tasks: [DownloadTask]) {}
    func indexTask(_ task: DownloadTask) {}
    func removeTask(_ task: DownloadTask) {}
    func removeAllItems() {}
    func updateTasks(_ tasks: [DownloadTask]) {}
}

// MARK: - Stub Haptic Manager

final class StubHapticManager: HapticManaging {
    func prepare() {}
    func lightImpact() {}
    func mediumImpact() {}
    func heavyImpact() {}
    func selectionChanged() {}
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {}
    func success() {}
    func warning() {}
    func error() {}
}

// MARK: - Stub Recent Folders Service

final class StubRecentFoldersService: RecentFoldersManaging {
    var recentFolders: [String] { ["/volume1/downloads"] }
    func addRecentFolder(_ path: String) {}
    func clearRecentFolders() {}
}

#endif
