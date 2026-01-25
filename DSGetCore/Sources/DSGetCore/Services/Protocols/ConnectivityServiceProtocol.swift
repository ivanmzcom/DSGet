import Foundation

/// Connection type enumeration.
public enum ConnectionType: String, Sendable, CaseIterable {
    case wifi
    case cellular
    case ethernet
    case unknown

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }

    /// Icon name for this connection type.
    public var iconName: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Protocol for connectivity status.
public protocol ConnectivityServiceProtocol: Sendable {

    /// Current connectivity status.
    var isConnected: Bool { get }

    /// Type of current connection.
    var connectionType: ConnectionType { get }

    /// Waits for connection with timeout.
    /// - Parameter timeout: Maximum time to wait.
    /// - Returns: True if connected, false if timeout.
    func waitForConnection(timeout: TimeInterval) async -> Bool
}
