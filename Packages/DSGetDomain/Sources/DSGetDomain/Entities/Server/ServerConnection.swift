import Foundation

/// Represents an active connection to a server.
/// Combines server configuration with session information.
public struct ServerConnection: Equatable, Sendable {
    public let server: Server
    public let session: Session
    public let connectedAt: Date

    public init(
        server: Server,
        session: Session,
        connectedAt: Date = Date()
    ) {
        self.server = server
        self.session = session
        self.connectedAt = connectedAt
    }

    /// Whether the connection is still valid (session not expired).
    public var isValid: Bool {
        session.isValid && !session.mightBeExpired()
    }

    /// Duration of the connection.
    public var connectionDuration: TimeInterval {
        Date().timeIntervalSince(connectedAt)
    }

    /// Server ID for convenience.
    public var serverID: ServerID {
        server.id
    }

    /// Server display name for convenience.
    public var displayName: String {
        server.displayName
    }
}

/// State of server management.
public enum ServerManagerState: Equatable, Sendable {
    case idle
    case loading
    case connecting(ServerID)
    case connected(ServerConnection)
    case error(String)

    public var isLoading: Bool {
        switch self {
        case .loading, .connecting: return true
        default: return false
        }
    }

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var activeConnection: ServerConnection? {
        if case .connected(let connection) = self { return connection }
        return nil
    }
}
