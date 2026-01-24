import Foundation

/// Protocol for editing task destination use case.
public protocol EditTaskDestinationUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameters:
    ///   - taskIDs: Array of task IDs to edit.
    ///   - destination: The new destination folder path.
    func execute(taskIDs: [TaskID], destination: String) async throws
}

/// Use case for changing task destination folder.
public final class EditTaskDestinationUseCase: EditTaskDestinationUseCaseProtocol, @unchecked Sendable {
    private let taskRepository: TaskRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol

    public init(
        taskRepository: TaskRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol
    ) {
        self.taskRepository = taskRepository
        self.cacheRepository = cacheRepository
    }

    public func execute(taskIDs: [TaskID], destination: String) async throws {
        guard !taskIDs.isEmpty else { return }
        guard !destination.isEmpty else {
            throw DomainError.pathNotFound(destination)
        }

        try await taskRepository.editTaskDestination(ids: taskIDs, destination: destination)
        await cacheRepository.invalidate(.tasks)
    }
}
