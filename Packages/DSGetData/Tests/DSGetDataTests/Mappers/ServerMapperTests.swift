import XCTest
@testable import DSGetData
@testable import DSGetDomain

final class ServerMapperTests: XCTestCase {

    var mapper: ServerMapper!

    override func setUp() {
        mapper = ServerMapper()
    }

    // MARK: - DTO to Entity Tests

    func testMapToEntityBasic() {
        // Given
        let dto = ServerDTO(
            id: UUID(),
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true,
            iconColor: "blue",
            createdAt: Date(),
            lastConnectedAt: nil
        )

        // When
        let entity = mapper.toEntity(dto)

        // Then
        XCTAssertEqual(entity.id.rawValue, dto.id)
        XCTAssertEqual(entity.name, "My NAS")
        XCTAssertEqual(entity.configuration.host, "nas.local")
        XCTAssertEqual(entity.configuration.port, 5001)
        XCTAssertTrue(entity.configuration.useHTTPS)
        XCTAssertEqual(entity.iconColor, .blue)
        XCTAssertNil(entity.lastConnectedAt)
    }

    func testMapToEntityWithLastConnected() {
        // Given
        let lastConnected = Date()
        let dto = ServerDTO(
            id: UUID(),
            name: "Office NAS",
            host: "192.168.1.100",
            port: 5000,
            useHTTPS: false,
            iconColor: "green",
            createdAt: Date(),
            lastConnectedAt: lastConnected
        )

        // When
        let entity = mapper.toEntity(dto)

        // Then
        XCTAssertEqual(entity.lastConnectedAt, lastConnected)
        XCTAssertFalse(entity.configuration.useHTTPS)
        XCTAssertEqual(entity.iconColor, .green)
    }

    func testMapToEntityUnknownColor() {
        // Given
        let dto = ServerDTO(
            id: UUID(),
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true,
            iconColor: "unknownColor",
            createdAt: Date()
        )

        // When
        let entity = mapper.toEntity(dto)

        // Then
        XCTAssertEqual(entity.iconColor, .default) // Falls back to default
    }

    // MARK: - Entity to DTO Tests

    func testMapToDTOBasic() {
        // Given
        let entity = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true,
            iconColor: .purple
        )

        // When
        let dto = mapper.toDTO(entity)

        // Then
        XCTAssertEqual(dto.id, entity.id.rawValue)
        XCTAssertEqual(dto.name, "My NAS")
        XCTAssertEqual(dto.host, "nas.local")
        XCTAssertEqual(dto.port, 5001)
        XCTAssertTrue(dto.useHTTPS)
        XCTAssertEqual(dto.iconColor, "purple")
        XCTAssertNil(dto.lastConnectedAt)
    }

    func testMapToDTOWithLastConnected() {
        // Given
        var entity = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001
        )
        entity.lastConnectedAt = Date()

        // When
        let dto = mapper.toDTO(entity)

        // Then
        XCTAssertNotNil(dto.lastConnectedAt)
    }

    // MARK: - Credentials Mapping Tests

    func testMapToCredentialsDTO() {
        // Given
        let serverID = ServerID()
        let credentials = Credentials(username: "admin", password: "secret123")

        // When
        let dto = mapper.toCredentialsDTO(serverID: serverID, credentials: credentials)

        // Then
        XCTAssertEqual(dto.serverID, serverID.rawValue)
        XCTAssertEqual(dto.username, "admin")
        XCTAssertEqual(dto.password, "secret123")
    }

    func testMapToCredentials() {
        // Given
        let dto = ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "myPassword"
        )

        // When
        let credentials = mapper.toCredentials(dto)

        // Then
        XCTAssertEqual(credentials.username, "admin")
        XCTAssertEqual(credentials.password, "myPassword")
    }

    // MARK: - All Colors Mapping Tests

    func testMapAllColorsToDTO() {
        let colors: [(ServerColor, String)] = [
            (.blue, "blue"),
            (.green, "green"),
            (.red, "red"),
            (.orange, "orange"),
            (.purple, "purple"),
            (.teal, "teal"),
            (.pink, "pink"),
            (.indigo, "indigo")
        ]

        for (color, expectedRaw) in colors {
            let entity = Server.create(
                name: "Test",
                host: "test.local",
                port: 5001,
                iconColor: color
            )
            let dto = mapper.toDTO(entity)
            XCTAssertEqual(dto.iconColor, expectedRaw, "Failed for color: \(color)")
        }
    }

    func testMapAllColorsToDomain() {
        let colors: [(String, ServerColor)] = [
            ("blue", .blue),
            ("green", .green),
            ("red", .red),
            ("orange", .orange),
            ("purple", .purple),
            ("teal", .teal),
            ("pink", .pink),
            ("indigo", .indigo)
        ]

        for (rawValue, expectedColor) in colors {
            let dto = ServerDTO(
                name: "Test",
                host: "test.local",
                port: 5001,
                iconColor: rawValue
            )
            let entity = mapper.toEntity(dto)
            XCTAssertEqual(entity.iconColor, expectedColor, "Failed for rawValue: \(rawValue)")
        }
    }
}
