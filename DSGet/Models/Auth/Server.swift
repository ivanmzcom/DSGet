import Foundation

/// Represents a Synology server configuration with metadata.
struct Server: Equatable, Sendable, Identifiable, Hashable {
    let id: ServerID
    var name: String
    var configuration: ServerConfiguration
    var iconColor: ServerColor
    let createdAt: Date
    var lastConnectedAt: Date?

    init(
        id: ServerID = ServerID(),
        name: String,
        configuration: ServerConfiguration,
        iconColor: ServerColor = .default,
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.configuration = configuration
        self.iconColor = iconColor
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
    }

    /// Display name for the server, falls back to host:port if name is empty.
    var displayName: String {
        name.isEmpty ? configuration.displayName : name
    }

    /// Whether this server has been connected to recently.
    var wasRecentlyConnected: Bool {
        guard let lastConnected = lastConnectedAt else { return false }
        return Date().timeIntervalSince(lastConnected) < 24 * 60 * 60
    }

    /// Creates a copy with updated connection timestamp.
    func withUpdatedConnection() -> Server {
        var copy = self
        copy.lastConnectedAt = Date()
        return copy
    }
}

// MARK: - Codable

extension Server: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case configuration
        case iconColor
        case createdAt
        case lastConnectedAt
    }
}

// MARK: - Validation

extension Server {
    /// Whether the server configuration is valid.
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        configuration.isValid
    }

    /// Validation error if server is invalid.
    var validationError: String? {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Server name cannot be empty"
        }
        return configuration.validationError
    }
}

// MARK: - Factory Methods

extension Server {
    /// Creates a new server with the given configuration.
    static func create(
        name: String,
        host: String,
        port: Int,
        useHTTPS: Bool = true,
        iconColor: ServerColor = .default
    ) -> Server {
        Server(
            name: name,
            configuration: ServerConfiguration(
                host: host,
                port: port,
                useHTTPS: useHTTPS
            ),
            iconColor: iconColor
        )
    }
}
