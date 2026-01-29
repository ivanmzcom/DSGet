import Foundation

// MARK: - Thread-Safe Configuration Storage

/// Thread-safe storage for API client configuration.
private actor APIConfigurationStorage {
    var baseURL: URL?
    var sessionID: String?

    func configure(serverConfig: ServerConfiguration, sessionID: String?) {
        let scheme = serverConfig.useHTTPS ? "https" : "http"
        self.baseURL = URL(string: "\(scheme)://\(serverConfig.host):\(serverConfig.port)")
        self.sessionID = sessionID
    }

    func setSessionID(_ sid: String?) {
        self.sessionID = sid
    }

    func clear() {
        self.baseURL = nil
        self.sessionID = nil
    }

    func getConfig() -> (baseURL: URL?, sessionID: String?) {
        (baseURL, sessionID)
    }
}

// MARK: - File Upload

/// Encapsulates file upload parameters.
public struct FileUpload: Sendable {
    public let data: Data
    public let fileName: String
    public let mimeType: String

    public init(data: Data, fileName: String, mimeType: String) {
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// MARK: - SynologyAPIClient

/// Base client for Synology API communication.
/// Thread-safe through actor-isolated configuration.
public final class SynologyAPIClient: Sendable {
    private let networkClient: NetworkClientProtocol
    private let decoder: JSONDecoder
    private let config: APIConfigurationStorage

    public init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
        self.decoder = JSONDecoder()
        self.config = APIConfigurationStorage()
    }

    // MARK: - Configuration

    /// Configures the client with server info.
    public func configure(serverConfig: ServerConfiguration, sessionID: String?) async {
        await config.configure(serverConfig: serverConfig, sessionID: sessionID)
    }

    /// Synchronous configuration for backwards compatibility.
    public func configure(serverConfig: ServerConfiguration, sessionID: String?) {
        Task { await config.configure(serverConfig: serverConfig, sessionID: sessionID) }
    }

    /// Configures with just session ID (for session updates).
    public func setSessionID(_ sid: String?) async {
        await config.setSessionID(sid)
    }

    /// Clears current configuration.
    public func clearConfiguration() async {
        await config.clear()
    }

    /// Synchronous clear for backwards compatibility.
    public func clearConfiguration() {
        Task { await config.clear() }
    }

    // MARK: - API Endpoints

    public enum APIEndpoint: String {
        case auth = "/webapi/auth.cgi"
        case downloadStation = "/webapi/DownloadStation/task.cgi"
        case rssSite = "/webapi/DownloadStation/RSSsite.cgi"
        case rssFeed = "/webapi/DownloadStation/RSSfeed.cgi"
        case btSearch = "/webapi/DownloadStation/btsearch.cgi"
        case fileStation = "/webapi/entry.cgi"
    }

    // MARK: - Request Methods

    /// Performs a GET request to Synology API.
    public func get<T: Decodable>(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        let (baseURL, sessionID) = await config.getConfig()

        #if DEBUG
        let baseURLString = baseURL?.absoluteString ?? "nil"
        let sessionStatus = sessionID != nil ? "present" : "nil"
        print(
            "[SynologyAPIClient] GET \(api).\(method) - baseURL: \(baseURLString), sessionID: \(sessionStatus)"
        )
        #endif

        guard let baseURL = baseURL else {
            #if DEBUG
            print("[SynologyAPIClient] ERROR: Not authenticated (no baseURL)")
            #endif
            throw DataError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        if let sid = sessionID {
            queryItems.append(URLQueryItem(name: "_sid", value: sid))
        }

        let (data, _) = try await networkClient.get(url: url, queryItems: queryItems)
        return try decode(data)
    }

    /// Performs a GET request and logs raw response (for debugging).
    public func getWithRawResponse<T: Decodable>(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        let (baseURL, sessionID) = await config.getConfig()

        guard let baseURL = baseURL else {
            throw DataError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        if let sid = sessionID {
            queryItems.append(URLQueryItem(name: "_sid", value: sid))
        }

        let (data, _) = try await networkClient.get(url: url, queryItems: queryItems)

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            NSLog("[SynologyAPIClient] RAW RESPONSE for %@.%@:", api, method)
            let chunkSize = 4000
            var index = jsonString.startIndex
            while index < jsonString.endIndex {
                let end = jsonString.index(index, offsetBy: chunkSize, limitedBy: jsonString.endIndex) ?? jsonString.endIndex
                NSLog("%@", String(jsonString[index..<end]))
                index = end
            }
        }
        #endif

        return try decode(data)
    }

    /// Performs a POST request to Synology API.
    public func post<T: Decodable>(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        body: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        let (baseURL, sessionID) = await config.getConfig()
        guard let baseURL = baseURL else {
            throw DataError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        if let sid = sessionID {
            queryItems.append(URLQueryItem(name: "_sid", value: sid))
        }

        let (data, _) = try await networkClient.post(url: url, queryItems: queryItems, body: body)
        return try decode(data)
    }

    /// Performs a multipart POST request for file uploads.
    public func postMultipart<T: Decodable>(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        file: FileUpload
    ) async throws -> SynoResponseDTO<T> {
        let (baseURL, sessionID) = await config.getConfig()
        guard let baseURL = baseURL else {
            throw DataError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        if let sid = sessionID {
            queryItems.append(URLQueryItem(name: "_sid", value: sid))
        }

        var multipartData = MultipartFormData()
        multipartData.addField(name: "api", value: api)
        multipartData.addField(name: "method", value: method)
        multipartData.addField(name: "version", value: String(version))
        for (key, value) in params {
            multipartData.addField(name: key, value: value)
        }
        multipartData.addFile(name: "file", data: file.data, fileName: file.fileName, mimeType: file.mimeType)

        let (data, _) = try await networkClient.postMultipart(url: url, queryItems: queryItems, multipartData: multipartData)
        return try decode(data)
    }

    /// Performs a multipart POST request with fields only (no file).
    public func postMultipartFields<T: Decodable>(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        fields: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        let (baseURL, sessionID) = await config.getConfig()
        guard let baseURL = baseURL else {
            throw DataError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        if let sid = sessionID {
            queryItems.append(URLQueryItem(name: "_sid", value: sid))
        }

        var multipartData = MultipartFormData()
        for (key, value) in fields {
            multipartData.addField(name: key, value: value)
        }

        #if DEBUG
        print("[SynologyAPIClient] POST multipart to: \(url)")
        print("[SynologyAPIClient] Query params: \(params)")
        print("[SynologyAPIClient] Fields: \(fields)")
        #endif

        let (data, _) = try await networkClient.postMultipart(url: url, queryItems: queryItems, multipartData: multipartData)

        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("[SynologyAPIClient] Multipart response: \(jsonString)")
        }
        #endif

        return try decode(data)
    }

    /// Performs an unauthenticated request (for login).
    public func getUnauthenticated<T: Decodable>(
        url: URL,
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        let fullURL = url.appendingPathComponent(endpoint.rawValue)
        let queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        let (data, _) = try await networkClient.get(url: fullURL, queryItems: queryItems)
        return try decode(data)
    }

    /// Performs an unauthenticated POST request (for login).
    public func postUnauthenticated<T: Decodable>(
        url: URL,
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        body: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        let fullURL = url.appendingPathComponent(endpoint.rawValue)
        let queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        let (data, _) = try await networkClient.post(url: fullURL, queryItems: queryItems, body: body)
        return try decode(data)
    }

    /// Downloads raw data from Synology API (for file downloads).
    public func downloadRawData(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> Data {
        try await downloadRawDataWithProgress(
            endpoint: endpoint,
            api: api,
            method: method,
            version: version,
            params: params,
            progress: nil
        )
    }

    /// Downloads raw data with progress tracking.
    public func downloadRawDataWithProgress(
        endpoint: APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        progress: DownloadProgressCallback?
    ) async throws -> Data {
        let (baseURL, sessionID) = await config.getConfig()
        guard let baseURL = baseURL else {
            throw DataError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent(endpoint.rawValue)
        var queryItems = buildQueryItems(api: api, method: method, version: version, params: params)

        if let sid = sessionID {
            queryItems.append(URLQueryItem(name: "_sid", value: sid))
        }

        let (data, _) = try await networkClient.downloadWithProgress(
            url: url,
            queryItems: queryItems,
            progress: progress
        )

        // Check if the response is an error JSON instead of file data
        if let jsonStart = String(data: data.prefix(50), encoding: .utf8),
           jsonStart.contains("\"success\":false") || jsonStart.contains("\"error\"") {
            if let response = try? decoder.decode(SynoResponseDTO<EmptyDataDTO>.self, from: data),
               !response.success,
               let error = response.error {
                throw DataError.apiError(error)
            }
        }

        return data
    }

    // MARK: - Private Methods

    private func buildQueryItems(
        api: String,
        method: String,
        version: Int,
        params: [String: String]
    ) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "api", value: api),
            URLQueryItem(name: "method", value: method),
            URLQueryItem(name: "version", value: String(version))
        ]

        for (key, value) in params {
            items.append(URLQueryItem(name: key, value: value))
        }

        return items
    }

    private func decode<T: Decodable>(_ data: Data) throws -> SynoResponseDTO<T> {
        do {
            let response = try decoder.decode(SynoResponseDTO<T>.self, from: data)
            if !response.success, let error = response.error {
                throw DataError.apiError(error)
            }
            return response
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.decodingFailed(error)
        }
    }
}
