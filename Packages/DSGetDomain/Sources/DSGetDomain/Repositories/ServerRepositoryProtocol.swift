import Foundation

/// Protocol for server data access.
/// Manages a single server configuration and its credentials.
public protocol ServerRepositoryProtocol: Sendable {

    /// Gets the saved server.
    /// - Returns: The server if one exists.
    func getServer() async throws -> Server?

    /// Saves a server with credentials.
    /// - Parameters:
    ///   - server: The server configuration.
    ///   - credentials: The credentials for authentication.
    func saveServer(_ server: Server, credentials: Credentials) async throws

    /// Removes the server and its credentials.
    func removeServer() async throws

    /// Gets the stored credentials.
    /// - Returns: The stored credentials.
    func getCredentials() async throws -> Credentials

    /// Checks if a server is configured.
    /// - Returns: True if a server exists.
    func hasServer() async -> Bool
}
