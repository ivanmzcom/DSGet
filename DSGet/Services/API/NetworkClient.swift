import Foundation

/// Progress callback for downloads.
typealias DownloadProgressCallback = @Sendable (Int64, Int64) -> Void

// MARK: - CharacterSet Extensions for Form Encoding

extension CharacterSet {
    /// Characters allowed in form-urlencoded keys (excludes &, =, +, and other reserved characters)
    static let urlQueryKeyAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        return allowed
    }()

    /// Characters allowed in form-urlencoded values (excludes &, =, +, and other reserved characters)
    static let urlQueryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+")
        return allowed
    }()
}

/// Protocol for network operations.
protocol NetworkClientProtocol: Sendable {
    func get(url: URL, queryItems: [URLQueryItem]) async throws -> (Data, HTTPURLResponse)
    func post(url: URL, queryItems: [URLQueryItem], body: [String: String]) async throws -> (Data, HTTPURLResponse)
    func postMultipart(url: URL, queryItems: [URLQueryItem], multipartData: MultipartFormData) async throws -> (Data, HTTPURLResponse)

    /// Downloads data with progress tracking.
    func downloadWithProgress(
        url: URL,
        queryItems: [URLQueryItem],
        progress: DownloadProgressCallback?
    ) async throws -> (Data, HTTPURLResponse)
}

/// URLSession-based network client implementation.
final class NetworkClient: NetworkClientProtocol, @unchecked Sendable {

    struct Configuration: Sendable {
        let timeoutInterval: TimeInterval
        let cachePolicy: URLRequest.CachePolicy

        static let `default` = Configuration(
            timeoutInterval: 30,
            cachePolicy: .reloadIgnoringLocalCacheData
        )

        init(timeoutInterval: TimeInterval, cachePolicy: URLRequest.CachePolicy) {
            self.timeoutInterval = timeoutInterval
            self.cachePolicy = cachePolicy
        }
    }

    private let session: URLSession

    static let shared: NetworkClient = {
        NetworkClient()
    }()

    init(configuration: Configuration = .default) {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeoutInterval
        sessionConfig.timeoutIntervalForResource = configuration.timeoutInterval * 2
        sessionConfig.requestCachePolicy = configuration.cachePolicy
        sessionConfig.httpAdditionalHeaders = ["Accept": "application/json"]

        self.session = URLSession(configuration: sessionConfig)
    }

    func get(url: URL, queryItems: [URLQueryItem]) async throws -> (Data, HTTPURLResponse) {
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

    func post(url: URL, queryItems: [URLQueryItem], body: [String: String]) async throws -> (Data, HTTPURLResponse) {
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

        // Manually encode body to ensure proper handling of special characters in values
        // First decode any existing percent-encoding, then re-encode for form submission
        let bodyString = body.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryKeyAllowed) ?? key
            // Decode first to avoid double-encoding (URLs may already have %XX sequences)
            let decodedValue = value.removingPercentEncoding ?? value
            let encodedValue = decodedValue.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? decodedValue
            return "\(encodedKey)=\(encodedValue)"
        }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)

        #if DEBUG
        print("[NetworkClient] POST to: \(finalURL)")
        print("[NetworkClient] Body: \(bodyString)")
        #endif

        return try await perform(request: request)
    }

    func postMultipart(url: URL, queryItems: [URLQueryItem], multipartData: MultipartFormData) async throws -> (Data, HTTPURLResponse) {
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

    func downloadWithProgress(
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

                if bytesReceived % 65536 == 0 {
                    progress?(bytesReceived, expectedLength)
                }
            }

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
