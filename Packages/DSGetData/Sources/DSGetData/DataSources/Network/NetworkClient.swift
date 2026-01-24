import Foundation

/// Progress callback for downloads.
public typealias DownloadProgressCallback = @Sendable (Int64, Int64) -> Void

/// Protocol for network operations.
public protocol NetworkClientProtocol: Sendable {
    func get(url: URL, queryItems: [URLQueryItem]) async throws -> (Data, HTTPURLResponse)
    func post(url: URL, queryItems: [URLQueryItem], body: [String: String]) async throws -> (Data, HTTPURLResponse)
    func postMultipart(url: URL, queryItems: [URLQueryItem], multipartData: MultipartFormData) async throws -> (Data, HTTPURLResponse)

    /// Downloads data with progress tracking.
    /// - Parameters:
    ///   - url: The URL to download from.
    ///   - queryItems: Query parameters.
    ///   - progress: Callback with (bytesReceived, totalBytes). totalBytes may be -1 if unknown.
    /// - Returns: The downloaded data and HTTP response.
    func downloadWithProgress(
        url: URL,
        queryItems: [URLQueryItem],
        progress: DownloadProgressCallback?
    ) async throws -> (Data, HTTPURLResponse)
}

/// URLSession-based network client implementation.
public final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {

    public struct Configuration: Sendable {
        public let timeoutInterval: TimeInterval
        public let cachePolicy: URLRequest.CachePolicy

        public static let `default` = Configuration(
            timeoutInterval: 30,
            cachePolicy: .reloadIgnoringLocalCacheData
        )

        public init(timeoutInterval: TimeInterval, cachePolicy: URLRequest.CachePolicy) {
            self.timeoutInterval = timeoutInterval
            self.cachePolicy = cachePolicy
        }
    }

    private let session: URLSession

    public static let shared = NetworkClient()

    public init(configuration: Configuration = .default) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        sessionConfig.requestCachePolicy = configuration.cachePolicy
        sessionConfig.httpAdditionalHeaders = ["Accept": "application/json"]

        self.session = URLSession(configuration: sessionConfig)
    }

    public func get(url: URL, queryItems: [URLQueryItem]) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"

        return try await perform(request: request)
    }

    public func post(url: URL, queryItems: [URLQueryItem], body: [String: String]) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = body.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = bodyComponents.percentEncodedQuery?.data(using: .utf8)

        return try await perform(request: request)
    }

    public func postMultipart(url: URL, queryItems: [URLQueryItem], multipartData: MultipartFormData) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(multipartData.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartData.build()

        return try await perform(request: request)
    }

    public func downloadWithProgress(
        url: URL,
        queryItems: [URLQueryItem],
        progress: DownloadProgressCallback?
    ) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }

        guard let finalURL = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        // Increase timeout for large file downloads
        request.timeoutInterval = 600

        do {
            let (asyncBytes, response) = try await session.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode)
            }

            let expectedLength = httpResponse.expectedContentLength
            var data = Data()
            if expectedLength > 0 {
                data.reserveCapacity(Int(expectedLength))
            }

            var bytesReceived: Int64 = 0

            for try await byte in asyncBytes {
                data.append(byte)
                bytesReceived += 1

                // Report progress every 64KB to avoid too many callbacks
                if bytesReceived % 65536 == 0 {
                    progress?(bytesReceived, expectedLength)
                }
            }

            // Final progress update
            progress?(bytesReceived, expectedLength)

            return (data, httpResponse)
        } catch let error as URLError {
            throw NetworkError.from(error)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.invalidResponse
        }
    }

    private func perform(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw NetworkError.httpError(statusCode: httpResponse.statusCode)
            }

            return (data, httpResponse)
        } catch let error as URLError {
            throw NetworkError.from(error)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.invalidResponse
        }
    }
}
