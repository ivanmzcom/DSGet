import Foundation

/// Request for creating a task.
public enum CreateTaskRequest: Sendable {
    case url(URL, destination: String?)
    case magnetLink(String, destination: String?)
    case torrentFile(data: Data, fileName: String, destination: String?)
}

/// Protocol for creating download tasks use case.
public protocol CreateTaskUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter request: The create task request.
    func execute(request: CreateTaskRequest) async throws
}

/// Use case for creating a new download task.
public final class CreateTaskUseCase: CreateTaskUseCaseProtocol, @unchecked Sendable {
    private let taskRepository: TaskRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol

    public init(
        taskRepository: TaskRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol
    ) {
        self.taskRepository = taskRepository
        self.cacheRepository = cacheRepository
    }

    public func execute(request: CreateTaskRequest) async throws {
        switch request {
        case .url(let url, let destination):
            try await taskRepository.createTask(url: url, destination: destination)

        case .magnetLink(let magnet, let destination):
            guard let url = URL(string: magnet) else {
                throw DomainError.invalidDownloadURL
            }
            try await taskRepository.createTask(url: url, destination: destination)

        case .torrentFile(let data, let fileName, let destination):
            guard !data.isEmpty else {
                throw DomainError.emptyTorrentFile
            }
            let sanitizedName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sanitizedName.isEmpty else {
                throw DomainError.invalidTorrentFileName
            }
            try await taskRepository.createTask(
                torrentData: data,
                fileName: sanitizedName,
                destination: destination
            )
        }

        // Invalidate cache to force refresh on next fetch
        await cacheRepository.invalidate(.tasks)
    }
}
