import Foundation

/// Represents an active connection to a server.
/// Combines server configuration with session information.
struct ServerConnection: Equatable, Sendable {
    let server: Server
    let session: Session
    let connectedAt: Date

    init(
        server: Server,
        session: Session,
        connectedAt: Date = Date()
    ) {
        self.server = server
        self.session = session
        self.connectedAt = connectedAt
    }

    /// Whether the connection is still valid (session not expired).
    var isValid: Bool {
        session.isValid && !session.mightBeExpired()
    }

    /// Duration of the connection.
    var connectionDuration: TimeInterval {
        Date().timeIntervalSince(connectedAt)
    }

    /// Server ID for convenience.
    var serverID: ServerID {
        server.id
    }

    /// Server display name for convenience.
    var displayName: String {
        server.displayName
    }
}

/// State of server management.
enum ServerManagerState: Equatable, Sendable {
    case idle
    case loading
    case connecting(ServerID)
    case connected(ServerConnection)
    case error(String)

    var isLoading: Bool {
        switch self {
        case .loading, .connecting: return true
        default: return false
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var activeConnection: ServerConnection? {
        if case .connected(let connection) = self { return connection }
        return nil
    }
}
