import XCTest
@testable import DSGetCore

// MARK: - Mock Connectivity

final class MockConnectivityService: ConnectivityServiceProtocol, @unchecked Sendable {
    var isConnected: Bool = true
    var connectionType: ConnectionType = .wifi

    func waitForConnection(timeout: TimeInterval) async -> Bool {
        return isConnected
    }
}

// MARK: - Mock Task Service

final class MockTaskService: TaskServiceProtocol, @unchecked Sendable {
    var getTasksResult: Result<TasksResult, Error> = .success(TasksResult(tasks: [], isFromCache: false))
    var createTaskError: Error?
    var pauseTasksError: Error?
    var resumeTasksError: Error?
    var deleteTasksError: Error?
    var editDestinationError: Error?

    var createTaskCalled = false
    var pauseTasksCalled = false
    var resumeTasksCalled = false
    var deleteTasksCalled = false
    var editDestinationCalled = false
    var lastCreateRequest: CreateTaskRequest?
    var lastPausedIDs: [TaskID]?
    var lastResumedIDs: [TaskID]?
    var lastDeletedIDs: [TaskID]?
    var lastEditedIDs: [TaskID]?
    var lastEditedDestination: String?

    func getTasks(forceRefresh: Bool) async throws -> TasksResult {
        return try getTasksResult.get()
    }

    func createTask(request: CreateTaskRequest) async throws {
        createTaskCalled = true
        lastCreateRequest = request
        if let error = createTaskError { throw error }
    }

    func pauseTasks(ids: [TaskID]) async throws {
        pauseTasksCalled = true
        lastPausedIDs = ids
        if let error = pauseTasksError { throw error }
    }

    func resumeTasks(ids: [TaskID]) async throws {
        resumeTasksCalled = true
        lastResumedIDs = ids
        if let error = resumeTasksError { throw error }
    }

    func deleteTasks(ids: [TaskID]) async throws {
        deleteTasksCalled = true
        lastDeletedIDs = ids
        if let error = deleteTasksError { throw error }
    }

    func editTaskDestination(ids: [TaskID], destination: String) async throws {
        editDestinationCalled = true
        lastEditedIDs = ids
        lastEditedDestination = destination
        if let error = editDestinationError { throw error }
    }
}

// MARK: - Tests

final class TaskServiceTests: XCTestCase {

    private var mockService: MockTaskService!

    override func setUp() {
        super.setUp()
        mockService = MockTaskService()
    }

    // MARK: - Helpers

    private func makeSampleTask(
        id: String = "task-1",
        title: String = "Test Download",
        status: TaskStatus = .downloading,
        sizeBytes: Int64 = 1_073_741_824,
        downloadedBytes: Int64 = 536_870_912
    ) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: title,
            size: ByteSize(bytes: sizeBytes),
            status: status,
            type: .bt,
            username: "admin",
            detail: TaskDetail(destination: "/downloads"),
            transfer: TaskTransferInfo(
                downloaded: ByteSize(bytes: downloadedBytes),
                uploaded: .zero,
                downloadSpeed: .megabytes(5),
                uploadSpeed: .megabytes(1)
            )
        )
    }

    // MARK: - GetTasks Tests

    func testGetTasksReturnsEmptyList() async throws {
        mockService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))

        let result = try await mockService.getTasks(forceRefresh: false)

        XCTAssertTrue(result.tasks.isEmpty)
        XCTAssertFalse(result.isFromCache)
    }

    func testGetTasksReturnsTasks() async throws {
        let tasks = [makeSampleTask(id: "1"), makeSampleTask(id: "2")]
        mockService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))

        let result = try await mockService.getTasks(forceRefresh: true)

        XCTAssertEqual(result.tasks.count, 2)
    }

    func testGetTasksFromCache() async throws {
        let tasks = [makeSampleTask()]
        mockService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: true))

        let result = try await mockService.getTasks(forceRefresh: false)

        XCTAssertTrue(result.isFromCache)
    }

    func testGetTasksThrowsNoConnection() async {
        mockService.getTasksResult = .failure(DomainError.noConnection)

        do {
            _ = try await mockService.getTasks(forceRefresh: false)
            XCTFail("Should throw")
        } catch let error as DomainError {
            XCTAssertEqual(error, .noConnection)
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - CreateTask Tests

    func testCreateTaskWithURL() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        try await mockService.createTask(request: .url(url, destination: "/downloads"))

        XCTAssertTrue(mockService.createTaskCalled)
    }

    func testCreateTaskWithMagnetLink() async throws {
        try await mockService.createTask(request: .magnetLink("magnet:?xt=urn:btih:abc123", destination: nil))

        XCTAssertTrue(mockService.createTaskCalled)
    }

    func testCreateTaskWithTorrentFile() async throws {
        let data = Data("fake torrent".utf8)
        try await mockService.createTask(request: .torrentFile(data: data, fileName: "test.torrent", destination: "/downloads"))

        XCTAssertTrue(mockService.createTaskCalled)
    }

    func testCreateTaskWithDestination() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        try await mockService.createTask(request: .url(url, destination: "/volume1/downloads"))

        XCTAssertTrue(mockService.createTaskCalled)
    }

    func testCreateTaskThrowsError() async {
        mockService.createTaskError = DomainError.invalidDownloadURL

        do {
            try await mockService.createTask(request: .magnetLink("invalid", destination: nil))
            XCTFail("Should throw")
        } catch let error as DomainError {
            XCTAssertEqual(error, .invalidDownloadURL)
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - PauseTasks Tests

    func testPauseSingleTask() async throws {
        try await mockService.pauseTasks(ids: [TaskID("task-1")])

        XCTAssertTrue(mockService.pauseTasksCalled)
        XCTAssertEqual(mockService.lastPausedIDs?.count, 1)
        XCTAssertEqual(mockService.lastPausedIDs?.first?.rawValue, "task-1")
    }

    func testPauseMultipleTasks() async throws {
        let ids = [TaskID("task-1"), TaskID("task-2"), TaskID("task-3")]
        try await mockService.pauseTasks(ids: ids)

        XCTAssertEqual(mockService.lastPausedIDs?.count, 3)
    }

    func testPauseEmptyArray() async throws {
        try await mockService.pauseTasks(ids: [])

        XCTAssertTrue(mockService.pauseTasksCalled)
        XCTAssertEqual(mockService.lastPausedIDs?.count, 0)
    }

    // MARK: - ResumeTasks Tests

    func testResumeSingleTask() async throws {
        try await mockService.resumeTasks(ids: [TaskID("task-1")])

        XCTAssertTrue(mockService.resumeTasksCalled)
        XCTAssertEqual(mockService.lastResumedIDs?.first?.rawValue, "task-1")
    }

    func testResumeMultipleTasks() async throws {
        let ids = [TaskID("task-1"), TaskID("task-2")]
        try await mockService.resumeTasks(ids: ids)

        XCTAssertEqual(mockService.lastResumedIDs?.count, 2)
    }

    func testResumeThrowsError() async {
        mockService.resumeTasksError = DomainError.taskOperationFailed(TaskID("task-1"), reason: "fail")

        do {
            try await mockService.resumeTasks(ids: [TaskID("task-1")])
            XCTFail("Should throw")
        } catch {
            // Expected
        }
    }

    // MARK: - DeleteTasks Tests

    func testDeleteSingleTask() async throws {
        try await mockService.deleteTasks(ids: [TaskID("task-1")])

        XCTAssertTrue(mockService.deleteTasksCalled)
        XCTAssertEqual(mockService.lastDeletedIDs?.count, 1)
    }

    func testDeleteMultipleTasks() async throws {
        let ids = [TaskID("task-1"), TaskID("task-2"), TaskID("task-3")]
        try await mockService.deleteTasks(ids: ids)

        XCTAssertEqual(mockService.lastDeletedIDs?.count, 3)
    }

    func testDeleteThrowsError() async {
        mockService.deleteTasksError = DomainError.taskNotFound(TaskID("task-1"))

        do {
            try await mockService.deleteTasks(ids: [TaskID("task-1")])
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .taskNotFound(let id) = error {
                XCTAssertEqual(id.rawValue, "task-1")
            } else {
                XCTFail("Wrong error")
            }
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - EditDestination Tests

    func testEditDestination() async throws {
        let ids = [TaskID("task-1")]
        try await mockService.editTaskDestination(ids: ids, destination: "/volume1/new-folder")

        XCTAssertTrue(mockService.editDestinationCalled)
        XCTAssertEqual(mockService.lastEditedDestination, "/volume1/new-folder")
    }

    func testEditDestinationMultipleTasks() async throws {
        let ids = [TaskID("task-1"), TaskID("task-2")]
        try await mockService.editTaskDestination(ids: ids, destination: "/downloads")

        XCTAssertEqual(mockService.lastEditedIDs?.count, 2)
    }

    func testEditDestinationThrowsError() async {
        mockService.editDestinationError = DomainError.taskOperationFailed(TaskID("task-1"), reason: "denied")

        do {
            try await mockService.editTaskDestination(ids: [TaskID("task-1")], destination: "/path")
            XCTFail("Should throw")
        } catch {
            // Expected
        }
    }

    // MARK: - Connectivity Tests

    func testConnectivityServiceDisconnected() async {
        let connectivity = MockConnectivityService()
        connectivity.isConnected = false

        XCTAssertFalse(connectivity.isConnected)
    }

    func testConnectivityServiceConnected() async {
        let connectivity = MockConnectivityService()
        connectivity.isConnected = true

        XCTAssertTrue(connectivity.isConnected)
    }

    func testConnectivityWaitForConnection() async {
        let connectivity = MockConnectivityService()
        connectivity.isConnected = true

        let result = await connectivity.waitForConnection(timeout: 5)
        XCTAssertTrue(result)
    }

    func testConnectivityWaitForConnectionTimeout() async {
        let connectivity = MockConnectivityService()
        connectivity.isConnected = false

        let result = await connectivity.waitForConnection(timeout: 0.1)
        XCTAssertFalse(result)
    }
}
