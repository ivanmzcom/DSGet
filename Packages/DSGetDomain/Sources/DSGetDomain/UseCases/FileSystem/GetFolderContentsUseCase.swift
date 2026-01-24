import Foundation

/// Protocol for getting folder contents use case.
public protocol GetFolderContentsUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter path: The folder path to list.
    /// - Returns: Array of items in the folder.
    func execute(path: String) async throws -> [FileSystemItem]
}

/// Use case for getting folder contents.
public final class GetFolderContentsUseCase: GetFolderContentsUseCaseProtocol, @unchecked Sendable {
    private let fileSystemRepository: FileSystemRepositoryProtocol

    public init(fileSystemRepository: FileSystemRepositoryProtocol) {
        self.fileSystemRepository = fileSystemRepository
    }

    public func execute(path: String) async throws -> [FileSystemItem] {
        guard !path.isEmpty else {
            throw DomainError.pathNotFound(path)
        }

        return try await fileSystemRepository.getFolderContents(path: path)
    }
}
