import Foundation

/// Protocol for fetching download tasks use case.
public protocol GetTasksUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter forceRefresh: If true, bypasses cache.
    /// - Returns: Result containing tasks and cache status.
    func execute(forceRefresh: Bool) async throws -> GetTasksResult
}

/// Use case for fetching download tasks with offline support.
public final class GetTasksUseCase: GetTasksUseCaseProtocol, @unchecked Sendable {
    private let taskRepository: TaskRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol
    private let connectivityRepository: ConnectivityRepositoryProtocol

    public init(
        taskRepository: TaskRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol,
        connectivityRepository: ConnectivityRepositoryProtocol
    ) {
        self.taskRepository = taskRepository
        self.cacheRepository = cacheRepository
        self.connectivityRepository = connectivityRepository
    }

    public func execute(forceRefresh: Bool = false) async throws -> GetTasksResult {
        // If not forcing refresh, try cache first
        if !forceRefresh, let cached = await cacheRepository.getCachedTasks() {
            return GetTasksResult(tasks: cached, isFromCache: true)
        }

        // Check connectivity
        let isConnected = await connectivityRepository.isConnected
        guard isConnected else {
            // Offline - return cached data or throw
            if let cached = await cacheRepository.getCachedTasks() {
                return GetTasksResult(tasks: cached, isFromCache: true)
            }
            throw DomainError.noConnection
        }

        // Fetch fresh data
        let tasks = try await taskRepository.getTasks(forceRefresh: forceRefresh)

        // Update cache
        await cacheRepository.setCachedTasks(tasks)

        return GetTasksResult(tasks: tasks, isFromCache: false)
    }
}
