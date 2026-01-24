import XCTest
@testable import DSGetData
@testable import DSGetDomain

final class ServerLocalDataSourceTests: XCTestCase {

    var dataSource: ServerLocalDataSource!
    var userDefaults: UserDefaults!
    var mockSecureStorage: MockSecureStorage!

    override func setUp() async throws {
        // Use a separate UserDefaults suite for testing
        userDefaults = UserDefaults(suiteName: "TestServerLocalDataSource")!
        userDefaults.removePersistentDomain(forName: "TestServerLocalDataSource")

        mockSecureStorage = MockSecureStorage()

        dataSource = ServerLocalDataSource(
            userDefaults: userDefaults,
            secureStorage: mockSecureStorage
        )
    }

    override func tearDown() async throws {
        userDefaults.removePersistentDomain(forName: "TestServerLocalDataSource")
    }

    // MARK: - Server Tests

    func testLoadServerWhenEmpty() {
        // When
        let server = dataSource.loadServer()

        // Then
        XCTAssertNil(server)
    }

    func testSaveAndLoadServer() throws {
        // Given
        let server = ServerDTO(
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true,
            iconColor: "blue"
        )

        // When
        try dataSource.saveServer(server)
        let loaded = dataSource.loadServer()

        // Then
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.id, server.id)
        XCTAssertEqual(loaded?.name, "My NAS")
        XCTAssertEqual(loaded?.host, "nas.local")
        XCTAssertEqual(loaded?.port, 5001)
        XCTAssertTrue(loaded?.useHTTPS ?? false)
    }

    func testSaveServerOverwrites() throws {
        // Given
        let server1 = ServerDTO(name: "NAS 1", host: "nas1.local", port: 5001)
        let server2 = ServerDTO(name: "NAS 2", host: "nas2.local", port: 5002)

        // When
        try dataSource.saveServer(server1)
        try dataSource.saveServer(server2)
        let loaded = dataSource.loadServer()

        // Then
        XCTAssertEqual(loaded?.name, "NAS 2")
        XCTAssertEqual(loaded?.host, "nas2.local")
    }

    func testRemoveServer() throws {
        // Given
        let server = ServerDTO(name: "My NAS", host: "nas.local", port: 5001)
        try dataSource.saveServer(server)

        // When
        try dataSource.removeServer()

        // Then
        XCTAssertNil(dataSource.loadServer())
    }

    func testHasServer() throws {
        // Given - Initially no server
        XCTAssertFalse(dataSource.hasServer)

        // When
        try dataSource.saveServer(ServerDTO(name: "My NAS", host: "nas.local", port: 5001))

        // Then
        XCTAssertTrue(dataSource.hasServer)

        // When
        try dataSource.removeServer()

        // Then
        XCTAssertFalse(dataSource.hasServer)
    }

    // MARK: - Credentials Tests

    func testSaveAndLoadCredentials() throws {
        // Given
        let credentials = ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "secret123"
        )

        // When
        try dataSource.saveCredentials(credentials)
        let loaded = try dataSource.loadCredentials()

        // Then
        XCTAssertEqual(loaded.username, "admin")
        XCTAssertEqual(loaded.password, "secret123")
    }

    func testLoadCredentialsWhenEmpty() {
        // When/Then
        XCTAssertThrowsError(try dataSource.loadCredentials())
    }

    func testDeleteCredentials() throws {
        // Given
        let credentials = ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "secret"
        )
        try dataSource.saveCredentials(credentials)

        // When
        try dataSource.deleteCredentials()

        // Then
        XCTAssertThrowsError(try dataSource.loadCredentials())
    }

    func testCredentialsExist() throws {
        // Initially no credentials
        XCTAssertFalse(dataSource.credentialsExist())

        // After saving
        try dataSource.saveCredentials(ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "secret"
        ))
        XCTAssertTrue(dataSource.credentialsExist())

        // After deleting
        try dataSource.deleteCredentials()
        XCTAssertFalse(dataSource.credentialsExist())
    }

    // MARK: - Clear All Tests

    func testClearAll() throws {
        // Given
        try dataSource.saveServer(ServerDTO(name: "My NAS", host: "nas.local", port: 5001))
        try dataSource.saveCredentials(ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "secret"
        ))

        // When
        try dataSource.clearAll()

        // Then
        XCTAssertNil(dataSource.loadServer())
        XCTAssertFalse(dataSource.credentialsExist())
    }

    // MARK: - Remove Server Also Clears Credentials

    func testRemoveServerClearsCredentials() throws {
        // Given
        try dataSource.saveServer(ServerDTO(name: "My NAS", host: "nas.local", port: 5001))
        try dataSource.saveCredentials(ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "secret"
        ))

        // When
        try dataSource.removeServer()

        // Then
        XCTAssertNil(dataSource.loadServer())
        XCTAssertFalse(dataSource.credentialsExist())
    }
}

// MARK: - Mock Secure Storage

final class MockSecureStorage: SecureStorageProtocol, @unchecked Sendable {
    var storage: [String: Data] = [:]
    var errorToThrow: Error?

    func save<T: Encodable>(_ item: T, forKey key: String) throws {
        if let error = errorToThrow { throw error }
        let data = try JSONEncoder().encode(item)
        storage[key] = data
    }

    func load<T: Decodable>(forKey key: String, type: T.Type) throws -> T {
        if let error = errorToThrow { throw error }
        guard let data = storage[key] else {
            throw DataError.notFound("Key not found: \(key)")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func delete(forKey key: String) throws {
        if let error = errorToThrow { throw error }
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        storage[key] != nil
    }
}
