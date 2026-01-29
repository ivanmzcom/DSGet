import Foundation

/// Auth service implementation combining authentication, session management, and server storage.
public final class AuthService: AuthServiceProtocol, @unchecked Sendable {
    private let apiClient: SynologyAPIClient
    private let networkClient: NetworkClientProtocol
    private let secureStorage: SecureStorageProtocol
    private let serverMapper: ServerMapper
    private let decoder: JSONDecoder

    // Keys for storage
    private let sessionKey = "DSGet.Session"
    private let credentialsKey = "DSGet.Credentials"
    private let serverKey = "dsget.server"
    private let serverCredentialsKey = "dsget.server.credentials"

    private let userDefaults: UserDefaults

    public init(
        apiClient: SynologyAPIClient,
        networkClient: NetworkClientProtocol = NetworkClient.shared,
        secureStorage: SecureStorageProtocol = KeychainService.shared,
        userDefaults: UserDefaults = .standard,
        serverMapper: ServerMapper = ServerMapper()
    ) {
        self.apiClient = apiClient
        self.networkClient = networkClient
        self.secureStorage = secureStorage
        self.userDefaults = userDefaults
        self.serverMapper = serverMapper
        self.decoder = JSONDecoder()
    }

    // MARK: - AuthServiceProtocol - Authentication

    public func login(request: LoginRequest) async throws -> Session {
        guard let baseURL = request.configuration.baseURL else {
            throw DomainError.invalidServerConfiguration
        }

        let authURL = baseURL.appendingPathComponent("/webapi/auth.cgi")

        var queryItems = [
            URLQueryItem(name: "api", value: "SYNO.API.Auth"),
            URLQueryItem(name: "method", value: "login"),
            URLQueryItem(name: "version", value: "6"),
            URLQueryItem(name: "account", value: request.credentials.username),
            URLQueryItem(name: "passwd", value: request.credentials.password),
            URLQueryItem(name: "session", value: "DownloadStation"),
            URLQueryItem(name: "format", value: "sid")
        ]

        if let otp = request.credentials.otpCode {
            queryItems.append(URLQueryItem(name: "otp_code", value: otp))
        }

        let (data, _) = try await networkClient.get(url: authURL, queryItems: queryItems)
        let response = try decodeLoginResponse(data)

        guard let loginData = response.data, let sid = loginData.sid else {
            if let error = response.error {
                if error.code == 403 {
                    throw DomainError.otpRequired
                } else if error.code == 404 {
                    throw DomainError.otpInvalid
                }
                throw DataError.apiError(error)
            }
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

        let authURL = baseURL.appendingPathComponent("/webapi/auth.cgi")

        let queryItems = [
            URLQueryItem(name: "api", value: "SYNO.API.Auth"),
            URLQueryItem(name: "method", value: "logout"),
            URLQueryItem(name: "version", value: "1"),
            URLQueryItem(name: "_sid", value: stored.sessionID),
            URLQueryItem(name: "session", value: "DownloadStation")
        ]

        // Logout from server (ignore errors)
        _ = try? await networkClient.get(url: authURL, queryItems: queryItems)

        // Clear local storage
        try? secureStorage.delete(forKey: sessionKey)
        try? secureStorage.delete(forKey: credentialsKey)

        await apiClient.clearConfiguration()
    }

    public func validateSession() async throws -> Session? {
        guard let session = try? await getStoredSession() else {
            return nil
        }

        // Try a simple API call to validate the session
        do {
            let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
                endpoint: .downloadStation,
                api: "SYNO.DownloadStation.Info",
                method: "getinfo",
                version: 1
            )
            return session
        } catch {
            // Session is invalid, try to refresh
            return try? await refreshSession()
        }
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

    // MARK: - AuthServiceProtocol - Server Management

    public func getServer() async throws -> Server? {
        guard let data = userDefaults.data(forKey: serverKey),
              let dto = try? decoder.decode(ServerDTO.self, from: data) else {
            return nil
        }
        return serverMapper.toEntity(dto)
    }

    public func saveServer(_ server: Server, credentials: Credentials) async throws {
        let serverDTO = serverMapper.toDTO(server)
        let serverData = try JSONEncoder().encode(serverDTO)
        userDefaults.set(serverData, forKey: serverKey)

        let credentialsDTO = serverMapper.toCredentialsDTO(serverID: server.id, credentials: credentials)
        try secureStorage.save(credentialsDTO, forKey: serverCredentialsKey)
    }

    public func removeServer() async throws {
        userDefaults.removeObject(forKey: serverKey)
        try? secureStorage.delete(forKey: serverCredentialsKey)

        // Also logout and clear session
        try await logout()
    }

    public func hasServer() async -> Bool {
        userDefaults.data(forKey: serverKey) != nil
    }

    public func getCredentials() async throws -> Credentials {
        do {
            let dto = try secureStorage.load(forKey: serverCredentialsKey, type: ServerCredentialsDTO.self)
            return serverMapper.toCredentials(dto)
        } catch {
            throw DomainError.serverCredentialsNotFound(ServerID())
        }
    }

    // MARK: - Private Methods

    private func decodeLoginResponse(_ data: Data) throws -> SynoResponseDTO<LoginResponseDTO> {
        do {
            let response = try decoder.decode(SynoResponseDTO<LoginResponseDTO>.self, from: data)
            if !response.success, let error = response.error {
                throw DataError.apiError(error)
            }
            return response
        } catch let error as DataError {
            throw error
        } catch let error as DomainError {
            throw error
        } catch {
            throw DataError.decodingFailed(error)
        }
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
