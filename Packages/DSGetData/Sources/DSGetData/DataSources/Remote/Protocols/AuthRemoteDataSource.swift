import Foundation

/// Protocol for authentication remote data operations.
public protocol AuthRemoteDataSource: Sendable {
    func login(
        baseURL: URL,
        username: String,
        password: String,
        otpCode: String?
    ) async throws -> LoginResponseDTO

    func logout(baseURL: URL, sessionID: String) async throws
}
