import Foundation

/// Configuration for connecting to a Synology server.
public struct ServerConfiguration: Equatable, Sendable, Hashable, Codable {
    public let host: String
    public let port: Int
    public let useHTTPS: Bool

    public init(host: String, port: Int, useHTTPS: Bool = true) {
        self.host = host
        self.port = port
        self.useHTTPS = useHTTPS
    }

    /// The URL scheme (http or https).
    public var scheme: String {
        useHTTPS ? "https" : "http"
    }

    /// Base URL for the server.
    public var baseURL: URL? {
        URL(string: "\(scheme)://\(host):\(port)")
    }

    /// Web API base URL.
    public var webAPIBaseURL: URL? {
        baseURL?.appendingPathComponent("webapi")
    }

    /// Display name for the server (host:port).
    public var displayName: String {
        "\(host):\(port)"
    }

    /// Default HTTPS port.
    public static let defaultHTTPSPort = 5001

    /// Default HTTP port.
    public static let defaultHTTPPort = 5000

    /// Creates configuration with default HTTPS port.
    public static func https(host: String, port: Int = defaultHTTPSPort) -> ServerConfiguration {
        ServerConfiguration(host: host, port: port, useHTTPS: true)
    }

    /// Creates configuration with default HTTP port.
    public static func http(host: String, port: Int = defaultHTTPPort) -> ServerConfiguration {
        ServerConfiguration(host: host, port: port, useHTTPS: false)
    }
}

// MARK: - Validation

extension ServerConfiguration {
    /// Validates the configuration.
    public var isValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        port > 0 &&
        port < 65_536
    }

    /// Validation error if configuration is invalid.
    public var validationError: String? {
        if host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Host cannot be empty"
        }
        if port <= 0 || port >= 65_536 {
            return "Port must be between 1 and 65535"
        }
        return nil
    }
}
