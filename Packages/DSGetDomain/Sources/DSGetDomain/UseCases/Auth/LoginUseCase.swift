import Foundation

/// Protocol for login use case.
public protocol LoginUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter request: Login request with server config and credentials.
    /// - Returns: The authenticated session.
    func execute(request: LoginRequest) async throws -> Session
}

/// Use case for logging in.
public final class LoginUseCase: LoginUseCaseProtocol, @unchecked Sendable {
    private let authRepository: AuthRepositoryProtocol

    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    public func execute(request: LoginRequest) async throws -> Session {
        // Validate configuration
        guard request.configuration.isValid else {
            throw DomainError.invalidServerConfiguration
        }

        // Validate credentials
        guard !request.credentials.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DomainError.invalidCredentials
        }
        guard !request.credentials.password.isEmpty else {
            throw DomainError.invalidCredentials
        }

        return try await authRepository.login(request: request)
    }
}
