import Foundation

/// Protocol for removing a server use case.
public protocol RemoveServerUseCaseProtocol: Sendable {
    /// Executes the use case.
    func execute() async throws
}

/// Use case for removing the server.
public final class RemoveServerUseCase: RemoveServerUseCaseProtocol, @unchecked Sendable {
    private let serverRepository: ServerRepositoryProtocol

    public init(serverRepository: ServerRepositoryProtocol) {
        self.serverRepository = serverRepository
    }

    public func execute() async throws {
        try await serverRepository.removeServer()
    }
}
