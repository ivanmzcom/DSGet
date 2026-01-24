import Foundation
import DSGetDomain

/// Implementation of TaskRepositoryProtocol with cache-first strategy.
public final class TaskRepositoryImpl: TaskRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: TaskRemoteDataSource
    private let cacheRepository: CacheRepositoryProtocol
    private let mapper: TaskMapper

    public init(
        remoteDataSource: TaskRemoteDataSource,
        cacheRepository: CacheRepositoryProtocol,
        mapper: TaskMapper = TaskMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheRepository = cacheRepository
        self.mapper = mapper
    }

    public func getTasks(forceRefresh: Bool) async throws -> [DownloadTask] {
        // Return cached if available and not forcing refresh
        if !forceRefresh, let cached = await cacheRepository.getCachedTasks() {
            return cached
        }

        // Fetch from remote
        let dto = try await remoteDataSource.fetchTasks(additional: ["detail", "transfer", "file", "tracker"])
        let tasks = mapper.mapToEntities(dto.tasks)

        // Update cache
        await cacheRepository.setCachedTasks(tasks)

        return tasks
    }

    public func createTask(url: URL, destination: String?) async throws {
        try await remoteDataSource.createTask(url: url.absoluteString, destination: destination)
        await cacheRepository.invalidate(.tasks)
    }

    public func createTask(torrentData: Data, fileName: String, destination: String?) async throws {
        try await remoteDataSource.createTask(torrentData: torrentData, fileName: fileName, destination: destination)
        await cacheRepository.invalidate(.tasks)
    }

    public func pauseTasks(ids: [TaskID]) async throws {
        let rawIDs = ids.map { $0.rawValue }
        try await remoteDataSource.pauseTasks(ids: rawIDs)
        await cacheRepository.invalidate(.tasks)
    }

    public func resumeTasks(ids: [TaskID]) async throws {
        let rawIDs = ids.map { $0.rawValue }
        try await remoteDataSource.resumeTasks(ids: rawIDs)
        await cacheRepository.invalidate(.tasks)
    }

    public func deleteTasks(ids: [TaskID]) async throws {
        let rawIDs = ids.map { $0.rawValue }
        try await remoteDataSource.deleteTasks(ids: rawIDs)
        await cacheRepository.invalidate(.tasks)
    }

    public func editTaskDestination(ids: [TaskID], destination: String) async throws {
        let rawIDs = ids.map { $0.rawValue }
        let results = try await remoteDataSource.editTaskDestination(ids: rawIDs, destination: destination)

        // Check for errors in results
        let errors = results.filter { $0.error != 0 }
        if let firstError = errors.first {
            let errorID = TaskID(firstError.id)
            throw DomainError.taskOperationFailed(errorID, reason: "Failed to edit destination (error: \(firstError.error))")
        }

        await cacheRepository.invalidate(.tasks)
    }
}
