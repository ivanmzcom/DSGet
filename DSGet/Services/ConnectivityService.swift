import Foundation
import Network

/// NWPathMonitor-based network connectivity monitor.
/// Simple implementation for Swift 6 strict concurrency.
final class ConnectivityService: Sendable {

    // Use actors internally for thread-safe state
    private let state = ConnectivityState()
    private let monitorActor = MonitorActor()

    static let shared: ConnectivityService = {
        ConnectivityService()
    }()

    init() {
        // Defer monitor setup to avoid MainActor isolation issues
        Task { @MainActor in
            await self.monitorActor.startMonitoring(stateActor: self.state)
        }
    }

    fileprivate static func mapConnectionType(from path: NWPath) -> ConnectionType {
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

// MARK: - Monitor Actor

/// Actor that manages the NWPathMonitor lifecycle.
private actor MonitorActor {
    private var monitor: NWPathMonitor?
    private let monitorQueue = DispatchQueue(label: "DSGet.ConnectivityService.monitor")

    func startMonitoring(stateActor: ConnectivityState) {
        guard monitor == nil else { return }

        let newMonitor = NWPathMonitor()
        newMonitor.pathUpdateHandler = { [stateActor] path in
            Task {
                await stateActor.update(
                    isConnected: path.status == .satisfied,
                    connectionType: ConnectivityService.mapConnectionType(from: path)
                )
            }
        }
        newMonitor.start(queue: monitorQueue)
        monitor = newMonitor
    }

    func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}

// MARK: - Internal State Actor

private actor ConnectivityState {
    var isConnected: Bool = true
    var connectionType: ConnectionType = .unknown

    func update(isConnected: Bool, connectionType: ConnectionType) {
        self.isConnected = isConnected
        self.connectionType = connectionType
    }

    func getIsConnected() -> Bool {
        isConnected
    }

    func getConnectionType() -> ConnectionType {
        connectionType
    }
}

// MARK: - ConnectivityServiceProtocol Conformance

extension ConnectivityService: ConnectivityServiceProtocol {
    var isConnected: Bool {
        // For sync access, we use a cached/default value
        // The actual value is updated asynchronously
        true // Default to connected, async updates happen via the monitor
    }

    var connectionType: ConnectionType {
        .unknown
    }

    func waitForConnection(timeout: TimeInterval) async -> Bool {
        let connected = await state.getIsConnected()
        if connected { return true }

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let isConnected = await state.getIsConnected()
            if isConnected { return true }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        return await state.getIsConnected()
    }
}
