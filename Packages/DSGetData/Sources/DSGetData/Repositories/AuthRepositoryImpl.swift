import Foundation
import DSGetDomain

/// Implementation of AuthRepositoryProtocol with Keychain storage.
public final class AuthRepositoryImpl: AuthRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: AuthRemoteDataSource
    private let secureStorage: SecureStorageProtocol
    private let apiClient: SynologyAPIClient
    private let mapper: AuthMapper

    private let sessionKey = "DSGet.Session"
    private let credentialsKey = "DSGet.Credentials"

    public init(
        remoteDataSource: AuthRemoteDataSource,
        secureStorage: SecureStorageProtocol,
        apiClient: SynologyAPIClient,
        mapper: AuthMapper = AuthMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.secureStorage = secureStorage
        self.apiClient = apiClient
        self.mapper = mapper
    }

    public func login(request: LoginRequest) async throws -> Session {
        guard let baseURL = request.configuration.baseURL else {
            throw DomainError.invalidServerConfiguration
        }

        let responseDTO = try await remoteDataSource.login(
            baseURL: baseURL,
            username: request.credentials.username,
            password: request.credentials.password,
            otpCode: request.credentials.otpCode
        )

        guard let sid = responseDTO.sid else {
            throw DomainError.invalidCredentials
        }

        let session = Session(
            sessionID: sid,
            serverConfiguration: request.configuration
        )

        // Store session and credentials
        let storedSession = StoredSessionDTO(
            sessionID: sid,
            host: request.configuration.host,
            port: request.configuration.port,
            useHTTPS: request.configuration.useHTTPS,
            createdAt: Date()
        )

        let storedCredentials = StoredCredentialsDTO(
            username: request.credentials.username,
            password: request.credentials.password
        )

        try secureStorage.save(storedSession, forKey: sessionKey)
        try secureStorage.save(storedCredentials, forKey: credentialsKey)

        // Configure API client
        await apiClient.configure(serverConfig: request.configuration, sessionID: sid)

        return session
    }

    public func logout() async throws {
        // Get stored session to know the URL
        guard let stored = try? secureStorage.load(forKey: sessionKey, type: StoredSessionDTO.self) else {
            // Already logged out
            await apiClient.clearConfiguration()
            return
        }

        let scheme = stored.useHTTPS ? "https" : "http"
        guard let baseURL = URL(string: "\(scheme)://\(stored.host):\(stored.port)") else {
            throw DomainError.invalidServerConfiguration
        }

        // Logout from server
        try? await remoteDataSource.logout(baseURL: baseURL, sessionID: stored.sessionID)

        // Clear local storage
        try? secureStorage.delete(forKey: sessionKey)
        try? secureStorage.delete(forKey: credentialsKey)

        await apiClient.clearConfiguration()
    }

    public func getStoredSession() async throws -> Session? {
        guard let stored = try? secureStorage.load(forKey: sessionKey, type: StoredSessionDTO.self) else {
            return nil
        }

        let config = ServerConfiguration(
            host: stored.host,
            port: stored.port,
            useHTTPS: stored.useHTTPS
        )

        // Configure API client with the stored session
        await apiClient.configure(serverConfig: config, sessionID: stored.sessionID)

        return Session(
            sessionID: stored.sessionID,
            serverConfiguration: config,
            createdAt: stored.createdAt
        )
    }

    public func getCurrentSession() throws -> Session? {
        guard let stored = try? secureStorage.load(forKey: sessionKey, type: StoredSessionDTO.self) else {
            return nil
        }

        let config = ServerConfiguration(
            host: stored.host,
            port: stored.port,
            useHTTPS: stored.useHTTPS
        )

        return Session(
            sessionID: stored.sessionID,
            serverConfiguration: config,
            createdAt: stored.createdAt
        )
    }

    public func isLoggedIn() async -> Bool {
        secureStorage.exists(forKey: sessionKey)
    }

    public func refreshSession() async throws -> Session {
        // Load stored credentials
        guard let storedSession = try? secureStorage.load(forKey: sessionKey, type: StoredSessionDTO.self),
              let storedCredentials = try? secureStorage.load(forKey: credentialsKey, type: StoredCredentialsDTO.self) else {
            throw DomainError.notAuthenticated
        }

        let config = ServerConfiguration(
            host: storedSession.host,
            port: storedSession.port,
            useHTTPS: storedSession.useHTTPS
        )

        let credentials = Credentials(
            username: storedCredentials.username,
            password: storedCredentials.password
        )

        let request = LoginRequest(configuration: config, credentials: credentials)
        return try await login(request: request)
    }
}

// MARK: - Storage DTOs

private struct StoredSessionDTO: Codable {
    let sessionID: String
    let host: String
    let port: Int
    let useHTTPS: Bool
    let createdAt: Date
}

private struct StoredCredentialsDTO: Codable {
    let username: String
    let password: String
}
