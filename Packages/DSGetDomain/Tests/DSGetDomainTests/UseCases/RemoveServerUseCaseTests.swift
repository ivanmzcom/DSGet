import XCTest
@testable import DSGetDomain

final class RemoveServerUseCaseTests: XCTestCase {

    var mockServerRepository: MockServerRepository!
    var useCase: RemoveServerUseCase!

    override func setUp() async throws {
        mockServerRepository = MockServerRepository()
        useCase = RemoveServerUseCase(serverRepository: mockServerRepository)
    }

    // MARK: - Success Tests

    func testExecuteSuccessfulRemove() async throws {
        // Given
        mockServerRepository.server = Server.create(
            name: "My NAS",
            host: "nas.local",
            port: 5001
        )
        mockServerRepository.credentials = Credentials(username: "admin", password: "secret")

        // When
        try await useCase.execute()

        // Then
        XCTAssertEqual(mockServerRepository.removeServerCallCount, 1)
        XCTAssertNil(mockServerRepository.server)
        XCTAssertNil(mockServerRepository.credentials)
    }

    func testExecuteRemoveWhenNoServerExists() async throws {
        // Given
        mockServerRepository.server = nil

        // When
        try await useCase.execute()

        // Then
        XCTAssertEqual(mockServerRepository.removeServerCallCount, 1)
    }

    // MARK: - Error Tests

    func testExecuteRepositoryError() async throws {
        // Given
        mockServerRepository.errorToThrow = DomainError.unknown("Storage error")

        // When/Then
        do {
            try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(mockServerRepository.removeServerCallCount, 1)
        }
    }
}
