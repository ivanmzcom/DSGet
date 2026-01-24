import Foundation

/// Protocol for pausing download tasks use case.
public protocol PauseTasksUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter taskIDs: Array of task IDs to pause.
    func execute(taskIDs: [TaskID]) async throws
}

/// Use case for pausing download tasks.
public final class PauseTasksUseCase: PauseTasksUseCaseProtocol, @unchecked Sendable {
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

        try await taskRepository.pauseTasks(ids: taskIDs)
        await cacheRepository.invalidate(.tasks)
    }
}
