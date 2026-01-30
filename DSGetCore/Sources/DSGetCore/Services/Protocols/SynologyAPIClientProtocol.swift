import Foundation

/// Protocol abstracting the Synology API client for testability.
public protocol SynologyAPIClientProtocol: Sendable {
    // MARK: - Configuration

    func configure(serverConfig: ServerConfiguration, sessionID: String?) async
    func configure(serverConfig: ServerConfiguration, sessionID: String?)
    func setSessionID(_ sid: String?) async
    func clearConfiguration() async
    func clearConfiguration()

    // MARK: - Authenticated Requests

    func get<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String]
    ) async throws -> SynoResponseDTO<T>

    func getWithRawResponse<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String]
    ) async throws -> SynoResponseDTO<T>

    // swiftlint:disable function_parameter_count
    func post<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String],
        body: [String: String]
    ) async throws -> SynoResponseDTO<T>

    func postMultipart<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String],
        file: FileUpload
    ) async throws -> SynoResponseDTO<T>

    func postMultipartFields<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String],
        fields: [String: String]
    ) async throws -> SynoResponseDTO<T>

    // MARK: - Unauthenticated Requests

    func getUnauthenticated<T: Decodable>(
        url: URL,
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String]
    ) async throws -> SynoResponseDTO<T>

    func postUnauthenticated<T: Decodable>(
        url: URL,
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String],
        body: [String: String]
    ) async throws -> SynoResponseDTO<T>

    // MARK: - Downloads

    func downloadRawData(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String]
    ) async throws -> Data

    func downloadRawDataWithProgress(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int,
        params: [String: String],
        progress: DownloadProgressCallback?
    ) async throws -> Data
    // swiftlint:enable function_parameter_count
}

// MARK: - Default Parameter Values

extension SynologyAPIClientProtocol {
    public func get<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        try await get(endpoint: endpoint, api: api, method: method, version: version, params: params)
    }

    public func getWithRawResponse<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        try await getWithRawResponse(endpoint: endpoint, api: api, method: method, version: version, params: params)
    }

    public func post<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        body: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        try await post(endpoint: endpoint, api: api, method: method, version: version, params: params, body: body)
    }

    public func postMultipart<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        file: FileUpload
    ) async throws -> SynoResponseDTO<T> {
        try await postMultipart(endpoint: endpoint, api: api, method: method, version: version, params: params, file: file)
    }

    public func postMultipartFields<T: Decodable>(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        fields: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        try await postMultipartFields(endpoint: endpoint, api: api, method: method, version: version, params: params, fields: fields)
    }

    public func getUnauthenticated<T: Decodable>(
        url: URL,
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        try await getUnauthenticated(url: url, endpoint: endpoint, api: api, method: method, version: version, params: params)
    }

    public func postUnauthenticated<T: Decodable>(
        url: URL,
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        body: [String: String] = [:]
    ) async throws -> SynoResponseDTO<T> {
        try await postUnauthenticated(url: url, endpoint: endpoint, api: api, method: method, version: version, params: params, body: body)
    }

    public func downloadRawData(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:]
    ) async throws -> Data {
        try await downloadRawData(endpoint: endpoint, api: api, method: method, version: version, params: params)
    }

    public func downloadRawDataWithProgress(
        endpoint: SynologyAPIClient.APIEndpoint,
        api: String,
        method: String,
        version: Int = 1,
        params: [String: String] = [:],
        progress: DownloadProgressCallback? = nil
    ) async throws -> Data {
        try await downloadRawDataWithProgress(endpoint: endpoint, api: api, method: method, version: version, params: params, progress: progress)
    }
}
