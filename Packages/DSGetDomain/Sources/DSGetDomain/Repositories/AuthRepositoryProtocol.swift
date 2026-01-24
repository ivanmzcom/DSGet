import Foundation

/// Protocol for authentication data access.
public protocol AuthRepositoryProtocol: Sendable {

    /// Logs in with credentials.
    /// - Parameter request: Login request containing server config and credentials.
    /// - Returns: The authenticated session.
    func login(request: LoginRequest) async throws -> Session

    /// Logs out the current session.
    func logout() async throws

    /// Gets the currently stored session.
    /// - Returns: The stored session, or nil if not logged in.
    func getStoredSession() async throws -> Session?

    /// Gets the current session synchronously (from cache/keychain).
    /// - Returns: The stored session, or nil if not logged in.
    func getCurrentSession() throws -> Session?

    /// Checks if user is currently logged in.
    /// - Returns: True if a valid session exists.
    func isLoggedIn() async -> Bool

    /// Refreshes the current session (re-login with stored credentials).
    /// - Returns: The new session.
    func refreshSession() async throws -> Session
}

/// Protocol for secure session storage.
public protocol SessionStorageProtocol: Sendable {

    /// Loads stored session.
    func loadSession() async throws -> Session

    /// Saves session with credentials.
    /// - Parameters:
    ///   - session: The session to save.
    ///   - credentials: The credentials to save for auto-relogin.
    func saveSession(_ session: Session, credentials: Credentials) async throws

    /// Deletes stored session and credentials.
    func deleteSession() async throws

    /// Whether a stored session exists.
    var hasStoredSession: Bool { get async }
}
