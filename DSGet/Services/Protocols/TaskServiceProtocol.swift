import Foundation

/// Request for creating a task.
enum CreateTaskRequest: Sendable {
    case url(URL, destination: String?)
    case magnetLink(String, destination: String?)
    case torrentFile(data: Data, fileName: String, destination: String?)
}

/// Result of fetching tasks.
struct TasksResult: Sendable {
    let tasks: [DownloadTask]
    let isFromCache: Bool

    init(tasks: [DownloadTask], isFromCache: Bool) {
        self.tasks = tasks
        self.isFromCache = isFromCache
    }
}

/// Protocol for task operations.
protocol TaskServiceProtocol: Sendable {

    /// Fetches all download tasks with caching and offline support.
    /// - Parameter forceRefresh: If true, bypasses cache.
    /// - Returns: Result containing tasks and cache status.
    func getTasks(forceRefresh: Bool) async throws -> TasksResult

    /// Creates a new download task.
    /// - Parameter request: The create task request.
    func createTask(request: CreateTaskRequest) async throws

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
