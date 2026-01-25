import Foundation

/// Protocol for authentication operations.
public protocol AuthServiceProtocol: Sendable {

    /// Logs in with server configuration and credentials.
    /// - Parameter request: Login request containing server config and credentials.
    /// - Returns: The authenticated session.
    func login(request: LoginRequest) async throws -> Session

    /// Logs out the current session.
    func logout() async throws

    /// Validates and retrieves the current session.
    /// - Returns: The current session if valid, nil otherwise.
    func validateSession() async throws -> Session?

    /// Gets the stored session without validation.
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

    // MARK: - Server Management

    /// Gets the saved server configuration.
    /// - Returns: The server if one exists.
    func getServer() async throws -> Server?

    /// Saves a server with credentials after successful authentication.
    /// - Parameters:
    ///   - server: The server configuration.
    ///   - credentials: The credentials for authentication.
    func saveServer(_ server: Server, credentials: Credentials) async throws

    /// Removes the server and its credentials.
    func removeServer() async throws

    /// Checks if a server is configured.
    /// - Returns: True if a server exists.
    func hasServer() async -> Bool

    /// Gets the stored credentials.
    /// - Returns: The stored credentials.
    func getCredentials() async throws -> Credentials
}
