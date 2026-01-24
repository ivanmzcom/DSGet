import XCTest
@testable import DSGetDomain

final class LoginUseCaseTests: XCTestCase {

    var mockAuthRepository: MockAuthRepository!
    var useCase: LoginUseCase!

    override func setUp() async throws {
        mockAuthRepository = MockAuthRepository()
        useCase = LoginUseCase(authRepository: mockAuthRepository)
    }

    // MARK: - Success Tests

    func testExecuteSuccessfulLogin() async throws {
        // Given
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")
        let request = LoginRequest(configuration: config, credentials: credentials)

        // When
        let session = try await useCase.execute(request: request)

        // Then
        XCTAssertEqual(session.sessionID, "test-sid")
        XCTAssertEqual(session.serverConfiguration.host, "nas.local")
        XCTAssertEqual(mockAuthRepository.loginCallCount, 1)
    }

    func testExecuteWithOTP() async throws {
        // Given
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret", otpCode: "123456")
        let request = LoginRequest(configuration: config, credentials: credentials)

        // When
        let session = try await useCase.execute(request: request)

        // Then
        XCTAssertNotNil(session)
        XCTAssertEqual(mockAuthRepository.loginCallCount, 1)
    }

    // MARK: - Error Tests

    func testExecuteInvalidCredentials() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.invalidCredentials
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let credentials = Credentials(username: "wrong", password: "wrong")
        let request = LoginRequest(configuration: config, credentials: credentials)

        // When/Then
        do {
            _ = try await useCase.execute(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidCredentials)
        }
    }

    func testExecuteOTPRequired() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.otpRequired
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")
        let request = LoginRequest(configuration: config, credentials: credentials)

        // When/Then
        do {
            _ = try await useCase.execute(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .otpRequired)
        }
    }

    func testExecuteServerUnreachable() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.serverUnreachable
        let config = ServerConfiguration(host: "invalid.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")
        let request = LoginRequest(configuration: config, credentials: credentials)

        // When/Then
        do {
            _ = try await useCase.execute(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .serverUnreachable)
        }
    }
}
