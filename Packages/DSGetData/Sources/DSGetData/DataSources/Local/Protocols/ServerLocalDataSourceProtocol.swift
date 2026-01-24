import Foundation

/// Protocol for local server data source.
/// Handles persistence of a single server configuration and credentials.
public protocol ServerLocalDataSourceProtocol: Sendable {

    // MARK: - Server

    /// Loads the server from storage.
    func loadServer() -> ServerDTO?

    /// Saves a server to storage.
    func saveServer(_ server: ServerDTO) throws

    /// Removes the server from storage.
    func removeServer() throws

    // MARK: - Credentials

    /// Saves credentials for the server.
    func saveCredentials(_ credentials: ServerCredentialsDTO) throws

    /// Loads credentials for the server.
    func loadCredentials() throws -> ServerCredentialsDTO

    /// Deletes the server credentials.
    func deleteCredentials() throws

    /// Checks if credentials exist.
    func credentialsExist() -> Bool

    // MARK: - Utilities

    /// Clears all server data (for logout/reset).
    func clearAll() throws

    /// Checks if a server is stored.
    var hasServer: Bool { get }
}
