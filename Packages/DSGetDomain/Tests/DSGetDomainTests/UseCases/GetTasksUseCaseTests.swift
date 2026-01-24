import XCTest
@testable import DSGetDomain

final class GetTasksUseCaseTests: XCTestCase {

    var mockTaskRepository: MockTaskRepository!
    var mockCacheRepository: MockCacheRepository!
    var mockConnectivityRepository: MockConnectivityRepository!
    var useCase: GetTasksUseCase!

    override func setUp() async throws {
        mockTaskRepository = MockTaskRepository()
        mockCacheRepository = MockCacheRepository()
        mockConnectivityRepository = MockConnectivityRepository()

        useCase = GetTasksUseCase(
            taskRepository: mockTaskRepository,
            cacheRepository: mockCacheRepository,
            connectivityRepository: mockConnectivityRepository
        )
    }

    // MARK: - Online Tests

    func testExecuteOnlineReturnsTasks() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        mockTaskRepository.tasks = [createTestTask(id: "1"), createTestTask(id: "2")]

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.tasks.count, 2)
        XCTAssertFalse(result.isFromCache)
        XCTAssertEqual(mockTaskRepository.getTasksCallCount, 1)
    }

    func testExecuteForceRefreshBypassesCache() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        await mockCacheRepository.setCachedTasks([createTestTask(id: "cached")])
        mockTaskRepository.tasks = [createTestTask(id: "fresh")]

        // When
        let result = try await useCase.execute(forceRefresh: true)

        // Then
        XCTAssertEqual(result.tasks.count, 1)
        XCTAssertEqual(result.tasks.first?.id.rawValue, "fresh")
        XCTAssertFalse(result.isFromCache)
    }

    func testExecuteUpdatesCacheOnSuccess() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        mockTaskRepository.tasks = [createTestTask(id: "new")]

        // When
        _ = try await useCase.execute()

        // Then
        let cached = await mockCacheRepository.getCachedTasks()
        XCTAssertEqual(cached?.count, 1)
        XCTAssertEqual(cached?.first?.id.rawValue, "new")
    }

    // MARK: - Offline Tests

    func testExecuteOfflineReturnsCachedTasks() async throws {
        // Given
        mockConnectivityRepository._isConnected = false
        await mockCacheRepository.setCachedTasks([createTestTask(id: "cached")])

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.tasks.count, 1)
        XCTAssertTrue(result.isFromCache)
        XCTAssertEqual(mockTaskRepository.getTasksCallCount, 0)
    }

    func testExecuteOfflineWithNoCacheThrowsError() async throws {
        // Given
        mockConnectivityRepository._isConnected = false
        // No cached tasks

        // When/Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DomainError)
        }
    }

    // MARK: - Error Handling Tests

    func testExecuteNetworkErrorFallsBackToCache() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        mockTaskRepository.errorToThrow = DomainError.timeout
        await mockCacheRepository.setCachedTasks([createTestTask(id: "cached")])

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.tasks.count, 1)
        XCTAssertTrue(result.isFromCache)
    }

    func testExecuteNetworkErrorWithNoCacheThrowsError() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        mockTaskRepository.errorToThrow = DomainError.timeout
        // No cached tasks

        // When/Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .timeout)
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
