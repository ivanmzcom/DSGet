import Foundation
@testable import DSGetCore

final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    // MARK: - Results

    var loginResult: Result<Session, Error> = .failure(DomainError.notAuthenticated)
    var logoutError: Error?
    var validateSessionResult: Session?
    var validateSessionError: Error?
    var getStoredSessionResult: Session?
    var getCurrentSessionResult: Session?
    var isLoggedInResult: Bool = false
    var refreshSessionResult: Result<Session, Error> = .failure(DomainError.notAuthenticated)
    var getServerResult: Server?
    var saveServerError: Error?
    var removeServerError: Error?
    var testConnectionError: Error?
    var hasServerResult: Bool = false
    var getCredentialsResult: Result<Credentials, Error> = .failure(DomainError.serverCredentialsNotFound(ServerID()))
    var getRecentServersResult: [Server] = []

    // MARK: - Spy

    var loginCalled = false
    var logoutCalled = false
    var validateSessionCalled = false
    var saveServerCalled = false
    var removeServerCalled = false
    var testConnectionCalled = false
    var clearRecentServersCalled = false
    var lastLoginRequest: LoginRequest?
    var lastSavedServer: Server?
    var lastSavedCredentials: Credentials?
    var lastTestConnectionConfiguration: ServerConfiguration?

    // MARK: - AuthServiceProtocol

    func login(request: LoginRequest) async throws -> Session {
        loginCalled = true
        lastLoginRequest = request
        return try loginResult.get()
    }

    func logout() async throws {
        logoutCalled = true
        if let error = logoutError { throw error }
    }

    func validateSession() async throws -> Session? {
        validateSessionCalled = true
        if let error = validateSessionError { throw error }
        return validateSessionResult
    }

    func getStoredSession() async throws -> Session? {
        getStoredSessionResult
    }

    func getCurrentSession() throws -> Session? {
        getCurrentSessionResult
    }

    func isLoggedIn() async -> Bool {
        isLoggedInResult
    }

    func refreshSession() async throws -> Session {
        try refreshSessionResult.get()
    }

    func testConnection(configuration: ServerConfiguration) async throws {
        testConnectionCalled = true
        lastTestConnectionConfiguration = configuration
        if let error = testConnectionError { throw error }
    }

    func getServer() async throws -> Server? {
        getServerResult
    }

    func saveServer(_ server: Server, credentials: Credentials) async throws {
        saveServerCalled = true
        lastSavedServer = server
        lastSavedCredentials = credentials
        if let error = saveServerError { throw error }
    }

    func removeServer() async throws {
        removeServerCalled = true
        if let error = removeServerError { throw error }
    }

    func hasServer() async -> Bool {
        hasServerResult
    }

    func getCredentials() async throws -> Credentials {
        try getCredentialsResult.get()
    }

    func getRecentServers() async -> [Server] {
        getRecentServersResult
    }

    func clearRecentServers() async {
        clearRecentServersCalled = true
        getRecentServersResult = []
    }
}
