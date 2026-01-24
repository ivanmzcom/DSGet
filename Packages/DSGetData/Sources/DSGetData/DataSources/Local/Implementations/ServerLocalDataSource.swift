import Foundation

/// Implementation of server local data source.
/// Uses UserDefaults for server config and Keychain for credentials.
public final class ServerLocalDataSource: ServerLocalDataSourceProtocol, @unchecked Sendable {

    // MARK: - Keys

    private enum Keys {
        static let server = "dsget.server"
        static let credentials = "dsget.server.credentials"
    }

    // MARK: - Dependencies

    private let userDefaults: UserDefaults
    private let secureStorage: SecureStorageProtocol
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Init

    public init(
        userDefaults: UserDefaults = .standard,
        secureStorage: SecureStorageProtocol = KeychainDataSource.shared
    ) {
        self.userDefaults = userDefaults
        self.secureStorage = secureStorage
    }

    // MARK: - Server

    public func loadServer() -> ServerDTO? {
        guard let data = userDefaults.data(forKey: Keys.server) else {
            return nil
        }
        return try? decoder.decode(ServerDTO.self, from: data)
    }

    public func saveServer(_ server: ServerDTO) throws {
        let data = try encoder.encode(server)
        userDefaults.set(data, forKey: Keys.server)
    }

    public func removeServer() throws {
        userDefaults.removeObject(forKey: Keys.server)
        try? deleteCredentials()
    }

    // MARK: - Credentials

    public func saveCredentials(_ credentials: ServerCredentialsDTO) throws {
        try secureStorage.save(credentials, forKey: Keys.credentials)
    }

    public func loadCredentials() throws -> ServerCredentialsDTO {
        try secureStorage.load(forKey: Keys.credentials, type: ServerCredentialsDTO.self)
    }

    public func deleteCredentials() throws {
        try secureStorage.delete(forKey: Keys.credentials)
    }

    public func credentialsExist() -> Bool {
        secureStorage.exists(forKey: Keys.credentials)
    }

    // MARK: - Utilities

    public func clearAll() throws {
        userDefaults.removeObject(forKey: Keys.server)
        try? deleteCredentials()
    }

    public var hasServer: Bool {
        loadServer() != nil
    }
}
