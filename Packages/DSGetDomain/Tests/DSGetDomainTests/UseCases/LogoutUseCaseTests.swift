import XCTest
@testable import DSGetDomain

final class LogoutUseCaseTests: XCTestCase {

    var mockAuthRepository: MockAuthRepository!
    var mockCacheRepository: MockCacheRepository!
    var useCase: LogoutUseCase!

    override func setUp() async throws {
        mockAuthRepository = MockAuthRepository()
        mockCacheRepository = MockCacheRepository()
        useCase = LogoutUseCase(
            authRepository: mockAuthRepository,
            cacheRepository: mockCacheRepository
        )
    }

    // MARK: - Success Tests

    func testExecuteSuccessfulLogout() async throws {
        // Given
        mockAuthRepository.session = Session(
            sessionID: "test-sid",
            serverConfiguration: ServerConfiguration(host: "nas.local", port: 5001)
        )

        // When
        try await useCase.execute()

        // Then
        XCTAssertEqual(mockAuthRepository.logoutCallCount, 1)
        let clearCount = await mockCacheRepository.clearAllCallCount
        XCTAssertEqual(clearCount, 1)
    }

    func testExecuteClearsCache() async throws {
        // Given
        await mockCacheRepository.setCachedTasks([
            createTestTask(id: "1"),
            createTestTask(id: "2")
        ])

        // When
        try await useCase.execute()

        // Then
        let cachedTasks = await mockCacheRepository.getCachedTasks()
        XCTAssertNil(cachedTasks)
    }

    func testExecuteWhenNotLoggedIn() async throws {
        // Given
        mockAuthRepository.session = nil

        // When
        try await useCase.execute()

        // Then
        XCTAssertEqual(mockAuthRepository.logoutCallCount, 1)
    }

    // MARK: - Error Tests

    func testExecuteAuthRepositoryError() async throws {
        // Given
        mockAuthRepository.errorToThrow = DomainError.noConnection

        // When/Then
        do {
            try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .noConnection)
        }
    }

    // MARK: - Helper Methods

    private func createTestTask(id: String) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: "Test \(id)",
            size: .megabytes(100),
            status: .downloading,
            type: .bt,
            username: "user",
            detail: nil,
            transfer: nil,
            files: [],
            trackers: []
        )
    }
}
