import Foundation

/// DTO for server persistence.
public struct ServerDTO: Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var host: String
    public var port: Int
    public var useHTTPS: Bool
    public var iconColor: String
    public var createdAt: Date
    public var lastConnectedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int,
        useHTTPS: Bool = true,
        iconColor: String = "blue",
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.useHTTPS = useHTTPS
        self.iconColor = iconColor
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
    }
}

/// DTO for server credentials persistence.
public struct ServerCredentialsDTO: Codable, Equatable, Sendable {
    public let serverID: UUID
    public let username: String
    public let password: String

    public init(serverID: UUID, username: String, password: String) {
        self.serverID = serverID
        self.username = username
        self.password = password
    }
}
