import Foundation

/// Protocol for logout use case.
public protocol LogoutUseCaseProtocol: Sendable {
    /// Executes the use case.
    func execute() async throws
}

/// Use case for logging out.
public final class LogoutUseCase: LogoutUseCaseProtocol, @unchecked Sendable {
    private let authRepository: AuthRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol

    public init(
        authRepository: AuthRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.cacheRepository = cacheRepository
    }

    public func execute() async throws {
        try await authRepository.logout()
        await cacheRepository.clearAll()
    }
}
