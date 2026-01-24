import XCTest
@testable import DSGetDomain

final class ServerTests: XCTestCase {

    // MARK: - Initialization Tests

    func testServerCreation() {
        // Given/When
        let server = Server(
            name: "My NAS",
            configuration: ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true),
            iconColor: .blue
        )

        // Then
        XCTAssertEqual(server.name, "My NAS")
        XCTAssertEqual(server.configuration.host, "nas.local")
        XCTAssertEqual(server.configuration.port, 5001)
        XCTAssertTrue(server.configuration.useHTTPS)
        XCTAssertEqual(server.iconColor, .blue)
        XCTAssertNil(server.lastConnectedAt)
    }

    func testServerFactoryMethod() {
        // Given/When
        let server = Server.create(
            name: "Office NAS",
            host: "192.168.1.100",
            port: 5000,
            useHTTPS: false,
            iconColor: .green
        )

        // Then
        XCTAssertEqual(server.name, "Office NAS")
        XCTAssertEqual(server.configuration.host, "192.168.1.100")
        XCTAssertEqual(server.configuration.port, 5000)
        XCTAssertFalse(server.configuration.useHTTPS)
        XCTAssertEqual(server.iconColor, .green)
    }

    // MARK: - Display Name Tests

    func testDisplayNameWithName() {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)

        // When/Then
        XCTAssertEqual(server.displayName, "My NAS")
    }

    func testDisplayNameFallbackToHostPort() {
        // Given
        let server = Server(
            name: "",
            configuration: ServerConfiguration(host: "nas.local", port: 5001)
        )

        // When/Then
        XCTAssertEqual(server.displayName, "nas.local:5001")
    }

    // MARK: - Validation Tests

    func testServerIsValid() {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)

        // When/Then
        XCTAssertTrue(server.isValid)
        XCTAssertNil(server.validationError)
    }

    func testServerInvalidEmptyName() {
        // Given
        let server = Server(
            name: "   ",
            configuration: ServerConfiguration(host: "nas.local", port: 5001)
        )

        // When/Then
        XCTAssertFalse(server.isValid)
        XCTAssertNotNil(server.validationError)
        XCTAssertEqual(server.validationError, "Server name cannot be empty")
    }

    func testServerInvalidEmptyHost() {
        // Given
        let server = Server(
            name: "My NAS",
            configuration: ServerConfiguration(host: "", port: 5001)
        )

        // When/Then
        XCTAssertFalse(server.isValid)
        XCTAssertNotNil(server.validationError)
    }

    func testServerInvalidPort() {
        // Given
        let server = Server(
            name: "My NAS",
            configuration: ServerConfiguration(host: "nas.local", port: 0)
        )

        // When/Then
        XCTAssertFalse(server.isValid)
    }

    // MARK: - Connection Timestamp Tests

    func testWithUpdatedConnection() {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        XCTAssertNil(server.lastConnectedAt)

        // When
        let updatedServer = server.withUpdatedConnection()

        // Then
        XCTAssertNotNil(updatedServer.lastConnectedAt)
        XCTAssertNil(server.lastConnectedAt) // Original unchanged
    }

    func testWasRecentlyConnectedTrue() {
        // Given
        var server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        server.lastConnectedAt = Date() // Just now

        // When/Then
        XCTAssertTrue(server.wasRecentlyConnected)
    }

    func testWasRecentlyConnectedFalse() {
        // Given
        var server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        server.lastConnectedAt = Date().addingTimeInterval(-48 * 60 * 60) // 48 hours ago

        // When/Then
        XCTAssertFalse(server.wasRecentlyConnected)
    }

    func testWasRecentlyConnectedNil() {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)

        // When/Then
        XCTAssertFalse(server.wasRecentlyConnected)
    }

    // MARK: - Codable Tests

    func testServerEncodeDecode() throws {
        // Given
        var server = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true,
            iconColor: .purple
        )
        server.lastConnectedAt = Date()

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(server)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Server.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, server.id)
        XCTAssertEqual(decoded.name, server.name)
        XCTAssertEqual(decoded.configuration.host, server.configuration.host)
        XCTAssertEqual(decoded.configuration.port, server.configuration.port)
        XCTAssertEqual(decoded.iconColor, server.iconColor)
    }

    // MARK: - Equatable Tests

    func testServerEquality() {
        // Given
        let id = ServerID()
        let createdAt = Date()
        let server1 = Server(
            id: id,
            name: "My NAS",
            configuration: ServerConfiguration(host: "nas.local", port: 5001),
            createdAt: createdAt
        )
        let server2 = Server(
            id: id,
            name: "My NAS",
            configuration: ServerConfiguration(host: "nas.local", port: 5001),
            createdAt: createdAt
        )

        // When/Then
        XCTAssertEqual(server1, server2)
    }

    func testServerInequality() {
        // Given
        let server1 = Server.create(name: "NAS 1", host: "nas1.local", port: 5001)
        let server2 = Server.create(name: "NAS 2", host: "nas2.local", port: 5001)

        // When/Then
        XCTAssertNotEqual(server1, server2)
    }

    // MARK: - Hashable Tests

    func testServerHashable() {
        // Given
        let server1 = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        let server2 = Server.create(name: "Other NAS", host: "other.local", port: 5001)

        // When
        var set = Set<Server>()
        set.insert(server1)
        set.insert(server2)
        set.insert(server1) // Duplicate

        // Then
        XCTAssertEqual(set.count, 2)
    }
}

// MARK: - ServerID Tests

final class ServerIDTests: XCTestCase {

    func testServerIDCreation() {
        // Given/When
        let id = ServerID()

        // Then
        XCTAssertNotNil(id.rawValue)
    }

    func testServerIDFromUUID() {
        // Given
        let uuid = UUID()

        // When
        let id = ServerID(uuid)

        // Then
        XCTAssertEqual(id.rawValue, uuid)
    }

    func testServerIDEquality() {
        // Given
        let uuid = UUID()
        let id1 = ServerID(uuid)
        let id2 = ServerID(uuid)

        // When/Then
        XCTAssertEqual(id1, id2)
    }
}

// MARK: - ServerConfiguration Tests

final class ServerConfigurationTests: XCTestCase {

    func testConfigurationDisplayName() {
        // Given
        let config = ServerConfiguration(host: "nas.local", port: 5001)

        // When/Then
        XCTAssertEqual(config.displayName, "nas.local:5001")
    }

    func testConfigurationBaseURL() {
        // Given
        let httpsConfig = ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        let httpConfig = ServerConfiguration(host: "nas.local", port: 5000, useHTTPS: false)

        // When/Then
        XCTAssertEqual(httpsConfig.baseURL?.absoluteString, "https://nas.local:5001")
        XCTAssertEqual(httpConfig.baseURL?.absoluteString, "http://nas.local:5000")
    }

    func testConfigurationIsValid() {
        // Given
        let validConfig = ServerConfiguration(host: "nas.local", port: 5001)
        let invalidHostConfig = ServerConfiguration(host: "", port: 5001)
        let invalidPortConfig = ServerConfiguration(host: "nas.local", port: 0)
        let invalidHighPortConfig = ServerConfiguration(host: "nas.local", port: 70000)

        // When/Then
        XCTAssertTrue(validConfig.isValid)
        XCTAssertFalse(invalidHostConfig.isValid)
        XCTAssertFalse(invalidPortConfig.isValid)
        XCTAssertFalse(invalidHighPortConfig.isValid)
    }
}

// MARK: - ServerColor Tests

final class ServerColorTests: XCTestCase {

    func testAllColorsExist() {
        // Given
        let allColors: [ServerColor] = [.blue, .green, .red, .orange, .purple, .teal, .pink, .indigo]

        // When/Then
        for color in allColors {
            XCTAssertFalse(color.rawValue.isEmpty)
            XCTAssertFalse(color.displayName.isEmpty)
        }
    }

    func testDefaultColor() {
        // When/Then
        XCTAssertEqual(ServerColor.default, .blue)
    }

    func testColorFromRawValue() {
        // Given/When
        let blue = ServerColor(rawValue: "blue")
        let invalid = ServerColor(rawValue: "invalid")

        // Then
        XCTAssertEqual(blue, .blue)
        XCTAssertNil(invalid)
    }
}
