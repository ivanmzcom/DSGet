import XCTest
@testable import DSGetData
@testable import DSGetDomain

final class ServerRepositoryImplTests: XCTestCase {

    var mockDataSource: MockServerLocalDataSource!
    var repository: ServerRepositoryImpl!

    override func setUp() async throws {
        mockDataSource = MockServerLocalDataSource()
        repository = ServerRepositoryImpl(localDataSource: mockDataSource)
    }

    // MARK: - Get Server Tests

    func testGetServerWhenExists() async throws {
        // Given
        mockDataSource.serverDTO = ServerDTO(
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true
        )

        // When
        let server = try await repository.getServer()

        // Then
        XCTAssertNotNil(server)
        XCTAssertEqual(server?.name, "My NAS")
        XCTAssertEqual(server?.configuration.host, "nas.local")
    }

    func testGetServerWhenNotExists() async throws {
        // Given
        mockDataSource.serverDTO = nil

        // When
        let server = try await repository.getServer()

        // Then
        XCTAssertNil(server)
    }

    // MARK: - Save Server Tests

    func testSaveServer() async throws {
        // Given
        let server = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001
        )
        let credentials = Credentials(username: "admin", password: "secret")

        // When
        try await repository.saveServer(server, credentials: credentials)

        // Then
        XCTAssertNotNil(mockDataSource.serverDTO)
        XCTAssertEqual(mockDataSource.serverDTO?.name, "My NAS")
        XCTAssertNotNil(mockDataSource.credentialsDTO)
        XCTAssertEqual(mockDataSource.credentialsDTO?.username, "admin")
    }

    // MARK: - Remove Server Tests

    func testRemoveServer() async throws {
        // Given
        mockDataSource.serverDTO = ServerDTO(name: "My NAS", host: "nas.local", port: 5001)
        mockDataSource.credentialsDTO = ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "secret"
        )

        // When
        try await repository.removeServer()

        // Then
        XCTAssertTrue(mockDataSource.removeServerCalled)
    }

    // MARK: - Get Credentials Tests

    func testGetCredentials() async throws {
        // Given
        mockDataSource.credentialsDTO = ServerCredentialsDTO(
            serverID: UUID(),
            username: "admin",
            password: "myPassword"
        )

        // When
        let credentials = try await repository.getCredentials()

        // Then
        XCTAssertEqual(credentials.username, "admin")
        XCTAssertEqual(credentials.password, "myPassword")
    }

    func testGetCredentialsNotFound() async throws {
        // Given
        mockDataSource.credentialsDTO = nil
        mockDataSource.loadCredentialsError = DataError.notFound("No credentials")

        // When/Then
        do {
            _ = try await repository.getCredentials()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DomainError)
        }
    }

    // MARK: - Has Server Tests

    func testHasServerTrue() async {
        // Given
        mockDataSource._hasServer = true

        // When
        let result = await repository.hasServer()

        // Then
        XCTAssertTrue(result)
    }

    func testHasServerFalse() async {
        // Given
        mockDataSource._hasServer = false

        // When
        let result = await repository.hasServer()

        // Then
        XCTAssertFalse(result)
    }
}

// MARK: - Mock Server Local DataSource

final class MockServerLocalDataSource: ServerLocalDataSourceProtocol, @unchecked Sendable {
    var serverDTO: ServerDTO?
    var credentialsDTO: ServerCredentialsDTO?
    var loadCredentialsError: Error?
    var removeServerCalled = false
    var _hasServer = false

    func loadServer() -> ServerDTO? {
        serverDTO
    }

    func saveServer(_ server: ServerDTO) throws {
        serverDTO = server
    }

    func removeServer() throws {
        removeServerCalled = true
        serverDTO = nil
        credentialsDTO = nil
    }

    func saveCredentials(_ credentials: ServerCredentialsDTO) throws {
        credentialsDTO = credentials
    }

    func loadCredentials() throws -> ServerCredentialsDTO {
        if let error = loadCredentialsError { throw error }
        guard let credentials = credentialsDTO else {
            throw DataError.notFound("No credentials")
        }
        return credentials
    }

    func deleteCredentials() throws {
        credentialsDTO = nil
    }

    func credentialsExist() -> Bool {
        credentialsDTO != nil
    }

    func clearAll() throws {
        serverDTO = nil
        credentialsDTO = nil
    }

    var hasServer: Bool {
        _hasServer
    }
}
