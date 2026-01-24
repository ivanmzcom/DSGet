import Foundation

/// Protocol for creating folder use case.
public protocol CreateFolderUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameters:
    ///   - parentPath: The parent folder path.
    ///   - name: The name of the new folder.
    func execute(parentPath: String, name: String) async throws
}

/// Use case for creating a folder.
public final class CreateFolderUseCase: CreateFolderUseCaseProtocol, @unchecked Sendable {
    private let fileSystemRepository: FileSystemRepositoryProtocol

    public init(fileSystemRepository: FileSystemRepositoryProtocol) {
        self.fileSystemRepository = fileSystemRepository
    }

    public func execute(parentPath: String, name: String) async throws {
        let sanitizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sanitizedName.isEmpty else {
            throw DomainError.folderCreationFailed(reason: "Folder name cannot be empty")
        }

        try await fileSystemRepository.createFolder(parentPath: parentPath, name: sanitizedName)
    }
}
