import Foundation

/// Protocol for resuming download tasks use case.
public protocol ResumeTasksUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter taskIDs: Array of task IDs to resume.
    func execute(taskIDs: [TaskID]) async throws
}

/// Use case for resuming download tasks.
public final class ResumeTasksUseCase: ResumeTasksUseCaseProtocol, @unchecked Sendable {
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

        try await taskRepository.resumeTasks(ids: taskIDs)
        await cacheRepository.invalidate(.tasks)
    }
}
