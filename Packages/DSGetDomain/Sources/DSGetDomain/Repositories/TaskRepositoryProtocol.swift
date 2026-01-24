import Foundation

/// Protocol for task data access.
public protocol TaskRepositoryProtocol: Sendable {

    /// Fetches all download tasks.
    /// - Parameter forceRefresh: If true, bypasses cache and fetches from server.
    /// - Returns: Result containing tasks or domain error.
    func getTasks(forceRefresh: Bool) async throws -> [DownloadTask]

    /// Creates a new download task from a URL.
    /// - Parameters:
    ///   - url: The download URL (HTTP, magnet, etc.)
    ///   - destination: Optional destination folder path.
    func createTask(url: URL, destination: String?) async throws

    /// Creates a new download task from a torrent file.
    /// - Parameters:
    ///   - torrentData: The torrent file data.
    ///   - fileName: The name of the torrent file.
    ///   - destination: Optional destination folder path.
    func createTask(torrentData: Data, fileName: String, destination: String?) async throws

    /// Pauses the specified tasks.
    /// - Parameter ids: Array of task IDs to pause.
    func pauseTasks(ids: [TaskID]) async throws

    /// Resumes the specified tasks.
    /// - Parameter ids: Array of task IDs to resume.
    func resumeTasks(ids: [TaskID]) async throws

    /// Deletes the specified tasks.
    /// - Parameter ids: Array of task IDs to delete.
    func deleteTasks(ids: [TaskID]) async throws

    /// Edits the destination folder for tasks.
    /// - Parameters:
    ///   - ids: Array of task IDs to edit.
    ///   - destination: The new destination folder path.
    func editTaskDestination(ids: [TaskID], destination: String) async throws
}

/// Result of fetching tasks.
public struct GetTasksResult: Sendable {
    public let tasks: [DownloadTask]
    public let isFromCache: Bool

    public init(tasks: [DownloadTask], isFromCache: Bool) {
        self.tasks = tasks
        self.isFromCache = isFromCache
    }
}
