import Foundation

/// Protocol for getting shared folders use case.
public protocol GetSharesUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Returns: Array of shared folder items.
    func execute() async throws -> [FileSystemItem]
}

/// Use case for getting shared folders.
public final class GetSharesUseCase: GetSharesUseCaseProtocol, @unchecked Sendable {
    private let fileSystemRepository: FileSystemRepositoryProtocol

    public init(fileSystemRepository: FileSystemRepositoryProtocol) {
        self.fileSystemRepository = fileSystemRepository
    }

    public func execute() async throws -> [FileSystemItem] {
        try await fileSystemRepository.getShares()
    }
}
