import Foundation

/// Protocol for deleting download tasks use case.
public protocol DeleteTasksUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter taskIDs: Array of task IDs to delete.
    func execute(taskIDs: [TaskID]) async throws
}

/// Use case for deleting download tasks.
public final class DeleteTasksUseCase: DeleteTasksUseCaseProtocol, @unchecked Sendable {
    private let taskRepository: TaskRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol

    public init(
        taskRepository: TaskRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol
    ) {
        self.taskRepository = taskRepository
        self.cacheRepository = cacheRepository
    }

    public func execute(taskIDs: [TaskID]) async throws {
        guard !taskIDs.isEmpty else { return }

        try await taskRepository.deleteTasks(ids: taskIDs)
        await cacheRepository.invalidate(.tasks)
    }
}
