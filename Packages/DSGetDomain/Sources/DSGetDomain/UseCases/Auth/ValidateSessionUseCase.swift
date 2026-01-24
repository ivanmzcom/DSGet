import Foundation

/// Protocol for validating session use case.
public protocol ValidateSessionUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Returns: The validated session.
    func execute() async throws -> Session
}

/// Use case for validating the current session.
public final class ValidateSessionUseCase: ValidateSessionUseCaseProtocol, @unchecked Sendable {
    private let authRepository: AuthRepositoryProtocol

    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    public func execute() async throws -> Session {
        guard let session = try await authRepository.getStoredSession() else {
            throw DomainError.notAuthenticated
        }

        // Check if session might be expired
        if session.mightBeExpired() {
            // Try to refresh
            return try await authRepository.refreshSession()
        }

        return session
    }
}

/// Protocol for checking if user is logged in.
public protocol CheckAuthStatusUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Returns: True if user is logged in.
    func execute() async -> Bool
}

/// Use case for checking authentication status.
public final class CheckAuthStatusUseCase: CheckAuthStatusUseCaseProtocol, @unchecked Sendable {
    private let authRepository: AuthRepositoryProtocol

    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    public func execute() async -> Bool {
        await authRepository.isLoggedIn()
    }
}

/// Protocol for getting stored session use case.
public protocol GetStoredSessionUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Returns: The stored session, or nil if not logged in.
    func execute() async throws -> Session?
}

/// Use case for getting the stored session without validation.
public final class GetStoredSessionUseCase: GetStoredSessionUseCaseProtocol, @unchecked Sendable {
    private let authRepository: AuthRepositoryProtocol

    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    public func execute() async throws -> Session? {
        try await authRepository.getStoredSession()
    }
}
