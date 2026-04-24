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

    // MARK: - API Decoding Tests

    func testDownloadTaskDTODecodesDocumentedStringNumbers() throws {
        let data = """
        {
            "id": "dbid_001",
            "type": "bt",
            "username": "admin",
            "title": "TOP 100 MIX",
            "size": "9427312332",
            "status": "downloading",
            "additional": {
                "detail": {
                    "create_time": "1341210005",
                    "destination": "Download",
                    "total_peers": "5",
                    "connected_seeders": "1",
                    "connected_leechers": "2",
                    "total_size": "9427312332"
                },
                "transfer": {
                    "size_downloaded": "100",
                    "size_uploaded": "20",
                    "speed_download": 500,
                    "speed_upload": "10"
                },
                "file": [{
                    "filename": "mix001.mp3",
                    "size": "41835",
                    "size_downloaded": "0",
                    "priority": "normal"
                }],
                "tracker": [{
                    "url": "https://tracker.example",
                    "status": "updating",
                    "update_timer": "30"
                }]
            }
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(DownloadTaskDTO.self, from: data)

        XCTAssertEqual(dto.size, 9_427_312_332)
        XCTAssertEqual(dto.additional?.detail?.createTime, 1_341_210_005)
        XCTAssertEqual(dto.additional?.detail?.connectedSeeders, 1)
        XCTAssertEqual(dto.additional?.detail?.totalSize, 9_427_312_332)
        XCTAssertEqual(dto.additional?.transfer?.sizeDownloaded, 100)
        XCTAssertEqual(dto.additional?.transfer?.speedUpload, 10)
        XCTAssertEqual(dto.additional?.file?.first?.size, 41_835)
        XCTAssertEqual(dto.additional?.tracker?.first?.updateInterval, 30)
    }

    func testSynoResponseDecodesIntegerErrorCode() throws {
        let data = #"{"success":false,"error":106}"#.data(using: .utf8)!

        let response = try JSONDecoder().decode(SynoResponseDTO<EmptyDataDTO>.self, from: data)

        XCTAssertEqual(response.error?.code, 106)
        XCTAssertEqual(response.error?.isSessionExpired, true)
    }

    func testTaskActionResultDecodesStringErrorCode() throws {
        let data = #"[{"id":"dbid_001","error":"405"}]"#.data(using: .utf8)!

        let results = try JSONDecoder().decode([TaskActionResultDTO].self, from: data)

        XCTAssertEqual(results.first?.id, "dbid_001")
        XCTAssertEqual(results.first?.error, 405)
    }

    func testTaskAdditionalDecodesPluralFilesKey() throws {
        let data = """
        {
            "files": [{
                "filename": "video.mkv",
                "size": "1024",
                "size_downloaded": "512"
            }]
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(TaskAdditionalDTO.self, from: data)

        XCTAssertEqual(dto.file?.first?.filename, "video.mkv")
        XCTAssertEqual(dto.file?.first?.size, 1_024)
        XCTAssertEqual(dto.file?.first?.sizeDownloaded, 512)
    }

    func testTaskMapperCreatesSingleFileFallbackWhenAPIProvidesNoFiles() throws {
        let dto = DownloadTaskDTO(
            id: "dbid_001",
            title: "movie.mkv",
            size: 2_048,
            status: "finished",
            type: "emule",
            username: "admin",
            additional: TaskAdditionalDTO(
                transfer: TaskTransferDTO(
                    sizeDownloaded: 2_048,
                    sizeUploaded: 0,
                    speedDownload: 0,
                    speedUpload: 0
                )
            )
        )

        let task = TaskMapper().mapToEntity(dto)

        XCTAssertEqual(task.files.count, 1)
        XCTAssertEqual(task.files.first?.id, "dbid_001")
        XCTAssertEqual(task.files.first?.name, "movie.mkv")
        XCTAssertEqual(task.files.first?.size.bytes, 2_048)
        XCTAssertEqual(task.files.first?.downloadedSize.bytes, 2_048)
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
