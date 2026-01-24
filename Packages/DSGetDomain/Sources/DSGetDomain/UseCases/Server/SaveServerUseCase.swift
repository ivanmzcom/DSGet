import Foundation

/// Protocol for saving a server use case.
public protocol SaveServerUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameters:
    ///   - server: The server configuration to save.
    ///   - credentials: The credentials for authentication.
    /// - Returns: The authenticated session for the server.
    func execute(server: Server, credentials: Credentials) async throws -> Session
}

/// Use case for saving the server configuration.
/// Validates credentials by authenticating before saving.
public final class SaveServerUseCase: SaveServerUseCaseProtocol, @unchecked Sendable {
    private let serverRepository: ServerRepositoryProtocol
    private let authRepository: AuthRepositoryProtocol

    public init(
        serverRepository: ServerRepositoryProtocol,
        authRepository: AuthRepositoryProtocol
    ) {
        self.serverRepository = serverRepository
        self.authRepository = authRepository
    }

    public func execute(server: Server, credentials: Credentials) async throws -> Session {
        // Validate server configuration
        guard server.isValid else {
            throw DomainError.invalidServerConfiguration
        }

        // Validate credentials
        guard !credentials.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.invalidCredentials
        }
        guard !credentials.password.isEmpty else {
            throw DomainError.invalidCredentials
        }

        // Try to authenticate first to verify credentials
        let loginRequest = LoginRequest(
            configuration: server.configuration,
            credentials: credentials
        )
        let session = try await authRepository.login(request: loginRequest)

        // If authentication succeeded, save the server
        let serverToSave = server.withUpdatedConnection()
        try await serverRepository.saveServer(serverToSave, credentials: credentials)

        return session
    }
}
