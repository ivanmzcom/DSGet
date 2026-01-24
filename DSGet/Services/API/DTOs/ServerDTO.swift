import Foundation

/// DTO for server persistence.
struct ServerDTO: Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var useHTTPS: Bool
    var iconColor: String
    var createdAt: Date
    var lastConnectedAt: Date?

    init(
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
struct ServerCredentialsDTO: Codable, Equatable, Sendable {
    let serverID: UUID
    let username: String
    let password: String

    init(serverID: UUID, username: String, password: String) {
        self.serverID = serverID
        self.username = username
        self.password = password
    }
}
