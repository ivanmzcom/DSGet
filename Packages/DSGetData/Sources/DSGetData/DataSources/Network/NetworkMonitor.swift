import Foundation
import Network
import DSGetDomain

/// NWPathMonitor-based network connectivity monitor.
public final class NetworkMonitorImpl: @unchecked Sendable {

    public private(set) var isConnected: Bool = true
    public private(set) var connectionType: ConnectionType = .unknown
    public private(set) var lastStatusChange: Date?

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "DSGetData.NetworkMonitor")
    private var isMonitoring = false

    public static let shared = NetworkMonitorImpl()

    public init() {}

    public func start() {
        guard !isMonitoring else { return }

        monitor.pathUpdateHandler = { [weak self] path in
            self?.updateStatus(from: path)
        }

        monitor.start(queue: queue)
        isMonitoring = true
    }

    public func stop() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }

    public func waitForConnection(timeout: TimeInterval) async -> Bool {
        if isConnected { return true }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if isConnected { return true }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        return isConnected
    }

    private func updateStatus(from path: NWPath) {
        isConnected = path.status == .satisfied
        connectionType = getConnectionType(from: path)
        lastStatusChange = Date()
    }

    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
}

// MARK: - ConnectivityRepositoryProtocol Conformance

extension NetworkMonitorImpl: ConnectivityRepositoryProtocol {
    // The stored properties `isConnected` and `connectionType` already satisfy
    // the async property requirements from the protocol.
    // Synchronous properties can satisfy async protocol requirements.
}
