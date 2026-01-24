//
//  NetworkMonitor.swift
//  DSGet
//
//  Network connectivity monitor using NWPathMonitor.
//

import Foundation
import Network

// MARK: - NetworkMonitor

/// Monitors network connection status.
/// Uses NWPathMonitor to detect connectivity changes.
@MainActor
@Observable
final class NetworkMonitor {

    // MARK: - Properties

    /// Indicates if there is internet connection.
    private(set) var isConnected: Bool = true

    /// Current connection type.
    private(set) var connectionType: ConnectionType = .unknown

    /// Date of the last status change.
    private(set) var lastStatusChange: Date?

    // MARK: - Private Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "es.ncrd.DSGet.NetworkMonitor")
    private var isMonitoring = false

    // MARK: - Connection Type

    enum ConnectionType: String {
        case wifi = "WiFi"
        case cellular = "Cellular"
        case ethernet = "Ethernet"
        case unknown = "Unknown"

        var icon: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            }
        }
    }

    // MARK: - Singleton

    static let shared = NetworkMonitor()

    private init() {}

    // MARK: - Public Methods

    /// Starts network monitoring.
    func start() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.updateStatus(from: path)
            }
        }

        monitor.start(queue: queue)
        isMonitoring = true

        #if DEBUG
        print("NetworkMonitor: Started monitoring")
        #endif
    }

    /// Stops network monitoring.
    func stop() {
        guard isMonitoring else { return }

        monitor.cancel()
        isMonitoring = false

        #if DEBUG
        print("NetworkMonitor: Stopped monitoring")
        #endif
    }

    /// Checks current connectivity synchronously.
    func checkConnectivity() -> Bool {
        return isConnected
    }

    /// Waits until connection is available.
    /// - Parameter timeout: Maximum wait time in seconds.
    /// - Returns: `true` if connection was established, `false` if timeout expired.
    func waitForConnection(timeout: TimeInterval = 30) async -> Bool {
        if isConnected { return true }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if isConnected { return true }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        return isConnected
    }

    // MARK: - Private Methods

    private func updateStatus(from path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        connectionType = getConnectionType(from: path)
        lastStatusChange = Date()

        #if DEBUG
        if wasConnected != isConnected {
            print("NetworkMonitor: Connection status changed to \(isConnected ? "connected" : "disconnected") via \(connectionType.rawValue)")
        }
        #endif
    }

    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - NetworkMonitor Extension for Testing

#if DEBUG
extension NetworkMonitor {
    /// Testing only: forces a connection state.
    func _setConnectionState(_ connected: Bool, type: ConnectionType = .wifi) {
        isConnected = connected
        connectionType = type
        lastStatusChange = Date()
    }
}
#endif
