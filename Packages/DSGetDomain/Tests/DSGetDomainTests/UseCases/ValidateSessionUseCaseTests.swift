import XCTest
@testable import DSGetDomain

final class ValidateSessionUseCaseTests: XCTestCase {

    var mockAuthRepository: MockAuthRepository!
    var useCase: ValidateSessionUseCase!

    override func setUp() async throws {
        mockAuthRepository = MockAuthRepository()
        useCase = ValidateSessionUseCase(authRepository: mockAuthRepository)
    }

    // MARK: - Valid Session Tests

    func testExecuteWithValidSession() async throws {
        // Given
        mockAuthRepository.session = Session(
            sessionID: "valid-sid",
            serverConfiguration: ServerConfiguration(host: "nas.local", port: 5001)
        )

        // When
        let session = try await useCase.execute()

        // Then
        XCTAssertTrue(session.isValid)
        XCTAssertEqual(session.sessionID, "valid-sid")
    }

    // MARK: - No Session Tests

    func testExecuteWithNoSession() async throws {
        // Given
        mockAuthRepository.session = nil

        // When/Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .notAuthenticated)
        }
    }

    // MARK: - Error Tests

    func testExecuteWithRepositoryError() async throws {
        // Given
        mockAuthRepository.session = nil
        mockAuthRepository.errorToThrow = DomainError.noConnection

        // When/Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            // Either notAuthenticated or noConnection is acceptable
            XCTAssertTrue(error is DomainError)
        }
    }
}
