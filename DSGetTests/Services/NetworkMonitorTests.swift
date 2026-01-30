import XCTest
@testable import DSGet

@MainActor
final class NetworkMonitorTests: XCTestCase {

    private var monitor: NetworkMonitor!

    override func setUp() async throws {
        try await super.setUp()
        monitor = NetworkMonitor.shared
        // Reset to known state for each test
        monitor.setConnectionStateForTesting(true, type: .wifi)
    }

    // MARK: - Initial State

    func testDefaultStateAfterReset() {
        // After setUp reset, should be connected via wifi
        XCTAssertTrue(monitor.isConnected)
        XCTAssertEqual(monitor.connectionType, .wifi)
    }

    // MARK: - Set Connection State for Testing

    func testSetConnectionStateForTestingConnected() {
        monitor.setConnectionStateForTesting(true, type: .wifi)

        XCTAssertTrue(monitor.isConnected)
        XCTAssertEqual(monitor.connectionType, .wifi)
        XCTAssertNotNil(monitor.lastStatusChange)
    }

    func testSetConnectionStateForTestingDisconnected() {
        monitor.setConnectionStateForTesting(false, type: .cellular)

        XCTAssertFalse(monitor.isConnected)
        XCTAssertEqual(monitor.connectionType, .cellular)
        XCTAssertNotNil(monitor.lastStatusChange)
    }

    func testSetConnectionStateForTestingEthernet() {
        monitor.setConnectionStateForTesting(true, type: .ethernet)

        XCTAssertTrue(monitor.isConnected)
        XCTAssertEqual(monitor.connectionType, .ethernet)
    }

    func testSetConnectionStateForTestingUnknown() {
        monitor.setConnectionStateForTesting(true, type: .unknown)

        XCTAssertTrue(monitor.isConnected)
        XCTAssertEqual(monitor.connectionType, .unknown)
    }

    // MARK: - Check Connectivity

    func testCheckConnectivityReturnsCurrentState() {
        monitor.setConnectionStateForTesting(true, type: .wifi)
        XCTAssertTrue(monitor.checkConnectivity())

        monitor.setConnectionStateForTesting(false, type: .wifi)
        XCTAssertFalse(monitor.checkConnectivity())
    }

    // MARK: - Connection Type Icon

    func testConnectionTypeIconWiFi() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wifi.icon, "wifi")
    }

    func testConnectionTypeIconCellular() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.cellular.icon, "antenna.radiowaves.left.and.right")
    }

    func testConnectionTypeIconEthernet() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.ethernet.icon, "cable.connector")
    }

    func testConnectionTypeIconUnknown() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.unknown.icon, "questionmark.circle")
    }

    // MARK: - Connection Type Raw Value

    func testConnectionTypeRawValueWiFi() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.wifi.rawValue, "WiFi")
    }

    func testConnectionTypeRawValueCellular() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.cellular.rawValue, "Cellular")
    }

    func testConnectionTypeRawValueEthernet() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.ethernet.rawValue, "Ethernet")
    }

    func testConnectionTypeRawValueUnknown() {
        XCTAssertEqual(NetworkMonitor.ConnectionType.unknown.rawValue, "Unknown")
    }

    // MARK: - Wait for Connection

    func testWaitForConnectionAlreadyConnected() async {
        monitor.setConnectionStateForTesting(true, type: .wifi)

        let result = await monitor.waitForConnection(timeout: 1.0)

        XCTAssertTrue(result)
    }

    func testWaitForConnectionNotConnectedTimesOut() async {
        monitor.setConnectionStateForTesting(false, type: .wifi)

        let result = await monitor.waitForConnection(timeout: 0.1)

        XCTAssertFalse(result)
    }

    func testWaitForConnectionBecomesConnected() async {
        monitor.setConnectionStateForTesting(false, type: .wifi)

        // Schedule connection to become available shortly
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            await MainActor.run {
                monitor.setConnectionStateForTesting(true, type: .wifi)
            }
        }

        let result = await monitor.waitForConnection(timeout: 1.0)

        XCTAssertTrue(result)
    }

    // MARK: - Last Status Change

    func testLastStatusChangeUpdatesOnStateChange() {
        let beforeChange = Date()

        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        monitor.setConnectionStateForTesting(false, type: .cellular)

        guard let lastChange = monitor.lastStatusChange else {
            XCTFail("lastStatusChange should be set")
            return
        }

        XCTAssertGreaterThan(lastChange, beforeChange)
    }

    // MARK: - Start and Stop Monitoring

    func testStartMonitoringDoesNotCrash() {
        // Just ensure start doesn't crash
        monitor.start()
    }

    func testStopMonitoringDoesNotCrash() {
        // Ensure stop doesn't crash
        monitor.stop()
    }

    func testStartAndStopMonitoring() {
        monitor.start()
        monitor.stop()
        // Test passes if no crash occurs
    }

    // MARK: - Singleton

    func testSharedInstanceIsSingleton() {
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared

        XCTAssertTrue(instance1 === instance2)
    }
}
