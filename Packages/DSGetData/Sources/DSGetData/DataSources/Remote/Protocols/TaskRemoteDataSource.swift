import Foundation

/// Protocol for task remote data operations.
public protocol TaskRemoteDataSource: Sendable {
    func fetchTasks(additional: [String]) async throws -> TaskListResponseDTO
    func createTask(url: String, destination: String?) async throws
    func createTask(torrentData: Data, fileName: String, destination: String?) async throws
    func pauseTasks(ids: [String]) async throws
    func resumeTasks(ids: [String]) async throws
    func deleteTasks(ids: [String]) async throws
    func editTaskDestination(ids: [String], destination: String) async throws -> [TaskEditResultDTO]
}
