import XCTest
@testable import DSGetDomain

// MARK: - Pause Tasks Use Case Tests

final class PauseTasksUseCaseTests: XCTestCase {

    var mockTaskRepository: MockTaskRepository!
    var mockCacheRepository: MockCacheRepository!
    var useCase: PauseTasksUseCase!

    override func setUp() async throws {
        mockTaskRepository = MockTaskRepository()
        mockCacheRepository = MockCacheRepository()
        useCase = PauseTasksUseCase(
            taskRepository: mockTaskRepository,
            cacheRepository: mockCacheRepository
        )
    }

    func testExecutePauseTasks() async throws {
        // Given
        let taskIDs = [TaskID("task-1"), TaskID("task-2")]

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then
        XCTAssertEqual(mockTaskRepository.pauseTasksCallCount, 1)
    }

    func testExecutePauseInvalidatesCache() async throws {
        // Given
        await mockCacheRepository.setCachedTasks([createTestTask(id: "1")])
        let taskIDs = [TaskID("task-1")]

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then
        let invalidateCount = await mockCacheRepository.invalidateCallCount
        XCTAssertEqual(invalidateCount, 1)
    }

    func testExecutePauseEmptyList() async throws {
        // Given
        let taskIDs: [TaskID] = []

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then - Use case returns early without calling repository for empty list
        XCTAssertEqual(mockTaskRepository.pauseTasksCallCount, 0)
    }

    func testExecutePauseRepositoryError() async throws {
        // Given
        mockTaskRepository.errorToThrow = DomainError.noConnection
        let taskIDs = [TaskID("task-1")]

        // When/Then
        do {
            try await useCase.execute(taskIDs: taskIDs)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .noConnection)
        }
    }

    private func createTestTask(id: String) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: "Test \(id)",
            size: .megabytes(100),
            status: .downloading,
            type: .bt,
            username: "user"
        )
    }
}

// MARK: - Resume Tasks Use Case Tests

final class ResumeTasksUseCaseTests: XCTestCase {

    var mockTaskRepository: MockTaskRepository!
    var mockCacheRepository: MockCacheRepository!
    var useCase: ResumeTasksUseCase!

    override func setUp() async throws {
        mockTaskRepository = MockTaskRepository()
        mockCacheRepository = MockCacheRepository()
        useCase = ResumeTasksUseCase(
            taskRepository: mockTaskRepository,
            cacheRepository: mockCacheRepository
        )
    }

    func testExecuteResumeTasks() async throws {
        // Given
        let taskIDs = [TaskID("task-1"), TaskID("task-2")]

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then
        XCTAssertEqual(mockTaskRepository.resumeTasksCallCount, 1)
    }

    func testExecuteResumeInvalidatesCache() async throws {
        // Given
        await mockCacheRepository.setCachedTasks([createTestTask(id: "1")])
        let taskIDs = [TaskID("task-1")]

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then
        let invalidateCount = await mockCacheRepository.invalidateCallCount
        XCTAssertEqual(invalidateCount, 1)
    }

    func testExecuteResumeRepositoryError() async throws {
        // Given
        mockTaskRepository.errorToThrow = DomainError.timeout
        let taskIDs = [TaskID("task-1")]

        // When/Then
        do {
            try await useCase.execute(taskIDs: taskIDs)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .timeout)
        }
    }

    private func createTestTask(id: String) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: "Test \(id)",
            size: .megabytes(100),
            status: .paused,
            type: .bt,
            username: "user"
        )
    }
}

// MARK: - Delete Tasks Use Case Tests

final class DeleteTasksUseCaseTests: XCTestCase {

    var mockTaskRepository: MockTaskRepository!
    var mockCacheRepository: MockCacheRepository!
    var useCase: DeleteTasksUseCase!

    override func setUp() async throws {
        mockTaskRepository = MockTaskRepository()
        mockCacheRepository = MockCacheRepository()
        useCase = DeleteTasksUseCase(
            taskRepository: mockTaskRepository,
            cacheRepository: mockCacheRepository
        )
    }

    func testExecuteDeleteTasks() async throws {
        // Given
        let taskIDs = [TaskID("task-1"), TaskID("task-2")]

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then
        XCTAssertEqual(mockTaskRepository.deleteTasksCallCount, 1)
    }

    func testExecuteDeleteInvalidatesCache() async throws {
        // Given
        await mockCacheRepository.setCachedTasks([
            createTestTask(id: "1"),
            createTestTask(id: "2")
        ])
        let taskIDs = [TaskID("task-1")]

        // When
        try await useCase.execute(taskIDs: taskIDs)

        // Then
        let invalidateCount = await mockCacheRepository.invalidateCallCount
        XCTAssertEqual(invalidateCount, 1)
    }

    func testExecuteDeleteRepositoryError() async throws {
        // Given
        mockTaskRepository.errorToThrow = DomainError.serverUnreachable
        let taskIDs = [TaskID("task-1")]

        // When/Then
        do {
            try await useCase.execute(taskIDs: taskIDs)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .serverUnreachable)
        }
    }

    private func createTestTask(id: String) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: "Test \(id)",
            size: .megabytes(100),
            status: .downloading,
            type: .bt,
            username: "user"
        )
    }
}

// MARK: - Create Task Use Case Tests

final class CreateTaskUseCaseTests: XCTestCase {

    var mockTaskRepository: MockTaskRepository!
    var mockCacheRepository: MockCacheRepository!
    var useCase: CreateTaskUseCase!

    override func setUp() async throws {
        mockTaskRepository = MockTaskRepository()
        mockCacheRepository = MockCacheRepository()
        useCase = CreateTaskUseCase(
            taskRepository: mockTaskRepository,
            cacheRepository: mockCacheRepository
        )
    }

    func testExecuteCreateTaskFromURL() async throws {
        // Given
        let url = URL(string: "https://example.com/file.zip")!
        let request = CreateTaskRequest.url(url, destination: "/downloads")

        // When
        try await useCase.execute(request: request)

        // Then
        XCTAssertEqual(mockTaskRepository.createTaskCallCount, 1)
    }

    func testExecuteCreateTaskInvalidatesCache() async throws {
        // Given
        await mockCacheRepository.setCachedTasks([createTestTask(id: "1")])
        let url = URL(string: "https://example.com/file.zip")!
        let request = CreateTaskRequest.url(url, destination: nil)

        // When
        try await useCase.execute(request: request)

        // Then
        let invalidateCount = await mockCacheRepository.invalidateCallCount
        XCTAssertEqual(invalidateCount, 1)
    }

    func testExecuteCreateTaskFromTorrent() async throws {
        // Given
        let torrentData = Data("fake torrent data".utf8)
        let request = CreateTaskRequest.torrentFile(
            data: torrentData,
            fileName: "test.torrent",
            destination: "/downloads"
        )

        // When
        try await useCase.execute(request: request)

        // Then
        XCTAssertEqual(mockTaskRepository.createTaskCallCount, 1)
    }

    func testExecuteCreateTaskFromMagnet() async throws {
        // Given
        let magnetLink = "magnet:?xt=urn:btih:example"
        let request = CreateTaskRequest.magnetLink(magnetLink, destination: nil)

        // When
        try await useCase.execute(request: request)

        // Then
        XCTAssertEqual(mockTaskRepository.createTaskCallCount, 1)
    }

    func testExecuteCreateTaskEmptyTorrent() async throws {
        // Given
        let request = CreateTaskRequest.torrentFile(data: Data(), fileName: "test.torrent", destination: nil)

        // When/Then
        do {
            try await useCase.execute(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .emptyTorrentFile)
        }
    }

    func testExecuteCreateTaskInvalidFileName() async throws {
        // Given
        let request = CreateTaskRequest.torrentFile(data: Data([1, 2, 3]), fileName: "   ", destination: nil)

        // When/Then
        do {
            try await useCase.execute(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? DomainError, .invalidTorrentFileName)
        }
    }

    func testExecuteCreateTaskRepositoryError() async throws {
        // Given
        mockTaskRepository.errorToThrow = DomainError.apiError(code: 400, message: "Invalid URL")
        let url = URL(string: "https://example.com/file.zip")!
        let request = CreateTaskRequest.url(url, destination: nil)

        // When/Then
        do {
            try await useCase.execute(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
            XCTAssertTrue(error is DomainError)
        }
    }

    private func createTestTask(id: String) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: "Test \(id)",
            size: .megabytes(100),
            status: .downloading,
            type: .bt,
            username: "user"
        )
    }
}
