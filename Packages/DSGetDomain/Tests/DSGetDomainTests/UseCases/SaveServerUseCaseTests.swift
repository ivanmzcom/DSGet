import XCTest
@testable import DSGetDomain

final class SaveServerUseCaseTests: XCTestCase {

    var mockServerRepository: MockServerRepository!
    var mockAuthRepository: MockAuthRepository!
    var useCase: SaveServerUseCase!

    override func setUp() async throws {
        mockServerRepository = MockServerRepository()
        mockAuthRepository = MockAuthRepository()
        useCase = SaveServerUseCase(
            serverRepository: mockServerRepository,
            authRepository: mockAuthRepository
        )
    }

    // MARK: - Success Tests

    func testExecuteSuccessfulSave() async throws {
        // Given
        let server = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001,
            useHTTPS: true
        )
        let credentials = Credentials(username: "admin", password: "secret")

        // When
        let session = try await useCase.execute(server: server, credentials: credentials)

        // Then
        XCTAssertEqual(session.sessionID, "test-sid")
        XCTAssertEqual(mockAuthRepository.loginCallCount, 1)
        XCTAssertEqual(mockServerRepository.saveServerCallCount, 1)
        XCTAssertNotNil(mockServerRepository.server)
        XCTAssertEqual(mockServerRepository.server?.name, "My NAS")
        XCTAssertNotNil(mockServerRepository.credentials)
    }

    func testExecuteUpdatesConnectionTimestamp() async throws {
        // Given
        let server = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001
        )
        let credentials = Credentials(username: "admin", password: "secret")

        // When
        _ = try await useCase.execute(server: server, credentials: credentials)

        // Then
        XCTAssertNotNil(mockServerRepository.server?.lastConnectedAt)
    }

    // MARK: - Validation Error Tests

    func testExecuteInvalidServerName() async throws {
        // Given
        let server = Server(
            name: "   ", // Empty after trimming
            configuration: ServerConfiguration(host: "nas.local", port: 5001)
        )
        let credentials = Credentials(username: "admin", password: "secret")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidServerConfiguration)
            XCTAssertEqual(mockAuthRepository.loginCallCount, 0)
            XCTAssertEqual(mockServerRepository.saveServerCallCount, 0)
        }
    }

    func testExecuteEmptyUsername() async throws {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        let credentials = Credentials(username: "   ", password: "secret")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidCredentials)
        }
    }

    func testExecuteEmptyPassword() async throws {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidCredentials)
        }
    }

    // MARK: - Authentication Error Tests

    func testExecuteAuthenticationFails() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.invalidCredentials
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        let credentials = Credentials(username: "wrong", password: "wrong")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidCredentials)
            // Server should not be saved if auth fails
            XCTAssertEqual(mockServerRepository.saveServerCallCount, 0)
        }
    }

    func testExecuteOTPRequired() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.otpRequired
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .otpRequired)
            XCTAssertEqual(mockServerRepository.saveServerCallCount, 0)
        }
    }

    func testExecuteServerUnreachable() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.serverUnreachable
        let server = Server.create(name: "My NAS", host: "invalid.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .serverUnreachable)
            XCTAssertEqual(mockServerRepository.saveServerCallCount, 0)
        }
    }

    // MARK: - Repository Error Tests

    func testExecuteRepositorySaveFails() async throws {
        // Given
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")

        // Auth succeeds but save fails
        mockServerRepository.errorToThrow = DomainError.unknown("Storage error")

        // When/Then
        do {
            _ = try await useCase.execute(server: server, credentials: credentials)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockAuthRepository.loginCallCount, 1)
            XCTAssertEqual(mockServerRepository.saveServerCallCount, 1)
        }
    }
}
