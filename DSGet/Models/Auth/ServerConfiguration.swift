import Foundation

/// Configuration for connecting to a Synology server.
struct ServerConfiguration: Equatable, Sendable, Hashable, Codable {
    let host: String
    let port: Int
    let useHTTPS: Bool

    init(host: String, port: Int, useHTTPS: Bool = true) {
        self.host = host
        self.port = port
        self.useHTTPS = useHTTPS
    }

    /// The URL scheme (http or https).
    var scheme: String {
        useHTTPS ? "https" : "http"
    }

    /// Base URL for the server.
    var baseURL: URL? {
        URL(string: "\(scheme)://\(host):\(port)")
    }

    /// Web API base URL.
    var webAPIBaseURL: URL? {
        baseURL?.appendingPathComponent("webapi")
    }

    /// Display name for the server (host:port).
    var displayName: String {
        "\(host):\(port)"
    }

    /// Default HTTPS port.
    static let defaultHTTPSPort = 5001

    /// Default HTTP port.
    static let defaultHTTPPort = 5000

    /// Creates configuration with default HTTPS port.
    static func https(host: String, port: Int = defaultHTTPSPort) -> ServerConfiguration {
        ServerConfiguration(host: host, port: port, useHTTPS: true)
    }

    /// Creates configuration with default HTTP port.
    static func http(host: String, port: Int = defaultHTTPPort) -> ServerConfiguration {
        ServerConfiguration(host: host, port: port, useHTTPS: false)
    }
}

// MARK: - Validation

extension ServerConfiguration {
    /// Validates the configuration.
    var isValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        port > 0 &&
        port < 65536
    }

    /// Validation error if configuration is invalid.
    var validationError: String? {
        if host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Host cannot be empty"
        }
        if port <= 0 || port >= 65536 {
            return "Port must be between 1 and 65535"
        }
        return nil
    }
}
