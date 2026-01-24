import Foundation
@testable import DSGetDomain

// MARK: - Mock Task Repository

final class MockTaskRepository: TaskRepositoryProtocol, @unchecked Sendable {
    var tasks: [DownloadTask] = []
    var getTasksCallCount = 0
    var createTaskCallCount = 0
    var pauseTasksCallCount = 0
    var resumeTasksCallCount = 0
    var deleteTasksCallCount = 0
    var editDestinationCallCount = 0

    var errorToThrow: Error?

    func getTasks(forceRefresh: Bool) async throws -> [DownloadTask] {
        getTasksCallCount += 1
        if let error = errorToThrow { throw error }
        return tasks
    }

    func createTask(url: URL, destination: String?) async throws {
        createTaskCallCount += 1
        if let error = errorToThrow { throw error }
    }

    func createTask(torrentData: Data, fileName: String, destination: String?) async throws {
        createTaskCallCount += 1
        if let error = errorToThrow { throw error }
    }

    func pauseTasks(ids: [TaskID]) async throws {
        pauseTasksCallCount += 1
        if let error = errorToThrow { throw error }
    }

    func resumeTasks(ids: [TaskID]) async throws {
        resumeTasksCallCount += 1
        if let error = errorToThrow { throw error }
    }

    func deleteTasks(ids: [TaskID]) async throws {
        deleteTasksCallCount += 1
        if let error = errorToThrow { throw error }
    }

    func editTaskDestination(ids: [TaskID], destination: String) async throws {
        editDestinationCallCount += 1
        if let error = errorToThrow { throw error }
    }
}

// MARK: - Mock Cache Repository

actor MockCacheRepository: CacheRepositoryProtocol {
    var cachedTasks: [DownloadTask]?
    var cachedFeeds: [RSSFeed]?
    var invalidateCallCount = 0
    var clearAllCallCount = 0

    func getCachedTasks() async -> [DownloadTask]? {
        cachedTasks
    }

    func setCachedTasks(_ tasks: [DownloadTask]) async {
        cachedTasks = tasks
    }

    func getCachedFeeds() async -> [RSSFeed]? {
        cachedFeeds
    }

    func setCachedFeeds(_ feeds: [RSSFeed]) async {
        cachedFeeds = feeds
    }

    func invalidate(_ key: CacheKey) async {
        invalidateCallCount += 1
        switch key {
        case .tasks: cachedTasks = nil
        case .feeds: cachedFeeds = nil
        default: break
        }
    }

    func clearAll() async {
        clearAllCallCount += 1
        cachedTasks = nil
        cachedFeeds = nil
    }
}

// MARK: - Mock Connectivity Repository

final class MockConnectivityRepository: ConnectivityRepositoryProtocol, @unchecked Sendable {
    var _isConnected: Bool = true
    var _connectionType: ConnectionType = .wifi

    var isConnected: Bool {
        get async { _isConnected }
    }

    var connectionType: ConnectionType {
        get async { _connectionType }
    }

    func waitForConnection(timeout: TimeInterval) async -> Bool {
        _isConnected
    }
}

// MARK: - Mock Auth Repository

final class MockAuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
    var session: Session?
    var loginCallCount = 0
    var logoutCallCount = 0
    var errorToThrow: Error?

    func login(request: LoginRequest) async throws -> Session {
        loginCallCount += 1
        if let error = errorToThrow { throw error }
        let session = Session(
            sessionID: "test-sid",
            serverConfiguration: request.configuration
        )
        self.session = session
        return session
    }

    func logout() async throws {
        logoutCallCount += 1
        if let error = errorToThrow { throw error }
        session = nil
    }

    func getStoredSession() async throws -> Session? {
        session
    }

    func getCurrentSession() throws -> Session? {
        session
    }

    func isLoggedIn() async -> Bool {
        session != nil
    }

    func refreshSession() async throws -> Session {
        if let error = errorToThrow { throw error }
        guard let session = session else {
            throw DomainError.notAuthenticated
        }
        return session
    }
}

// MARK: - Mock RSS Repository

final class MockRSSRepository: RSSRepositoryProtocol, @unchecked Sendable {
    var feeds: [RSSFeed] = []
    var feedItems: [RSSFeedItem] = []
    var getFeedsCallCount = 0
    var getFeedItemsCallCount = 0
    var refreshFeedCallCount = 0
    var errorToThrow: Error?

    func getFeeds(forceRefresh: Bool) async throws -> [RSSFeed] {
        getFeedsCallCount += 1
        if let error = errorToThrow { throw error }
        return feeds
    }

    func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem> {
        getFeedItemsCallCount += 1
        if let error = errorToThrow { throw error }
        return PaginatedResult(items: feedItems, total: feedItems.count)
    }

    func refreshFeed(id: FeedID) async throws {
        refreshFeedCallCount += 1
        if let error = errorToThrow { throw error }
    }
}

