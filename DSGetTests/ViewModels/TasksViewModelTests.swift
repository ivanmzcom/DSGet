import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class TasksViewModelTests: XCTestCase {

    private var mockTaskService: MockTaskService!
    private var mockWidgetSync: MockWidgetDataSyncService!
    private var sut: TasksViewModel!

    override func setUp() {
        super.setUp()
        mockTaskService = MockTaskService()
        mockWidgetSync = MockWidgetDataSyncService()
    }

    // MARK: - Helpers

    private func makeSUT() -> TasksViewModel {
        TasksViewModel(taskService: mockTaskService, widgetSyncService: mockWidgetSync)
    }

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

    // MARK: - Fetch Tests

    func testFetchTasksSuccess() async {
        sut = makeSUT()
        let tasks = [makeSampleTask(id: "1"), makeSampleTask(id: "2")]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))

        await sut.fetchTasks()

        XCTAssertEqual(sut.tasks.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isOfflineMode)
        XCTAssertNil(sut.currentError)
    }

    func testFetchTasksSyncsWidget() async {
        sut = makeSUT()
        let tasks = [makeSampleTask()]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))

        await sut.fetchTasks()

        XCTAssertTrue(mockWidgetSync.syncDownloadsCalled)
        XCTAssertEqual(mockWidgetSync.lastSyncedTasks.count, 1)
    }

    func testFetchTasksFromCache() async {
        sut = makeSUT()
        let tasks = [makeSampleTask()]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: true))

        await sut.fetchTasks()

        XCTAssertTrue(sut.isOfflineMode)
    }

    func testFetchTasksNoConnectionError() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .failure(DomainError.noConnection)

        await sut.fetchTasks()

        XCTAssertTrue(sut.isOfflineMode)
        XCTAssertTrue(mockWidgetSync.setConnectionErrorCalled)
        XCTAssertNotNil(sut.currentError)
    }

    func testFetchTasksGenericError() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .failure(DomainError.notAuthenticated)

        await sut.fetchTasks()

        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.currentError)
    }

    // MARK: - Active Download Count

    func testActiveDownloadCount() async {
        sut = makeSUT()
        let tasks = [
            makeSampleTask(id: "1", status: .downloading),
            makeSampleTask(id: "2", status: .downloading),
            makeSampleTask(id: "3", status: .paused),
            makeSampleTask(id: "4", status: .finished)
        ]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))

        await sut.fetchTasks()

        XCTAssertEqual(sut.activeDownloadCount, 2)
    }

    // MARK: - Delete Task

    func testDeleteTaskSuccess() async {
        sut = makeSUT()
        let task = makeSampleTask(id: "1")
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task], isFromCache: false))
        await sut.fetchTasks()

        await sut.deleteTask(task)

        XCTAssertTrue(mockTaskService.deleteTasksCalled)
        XCTAssertTrue(sut.tasks.isEmpty)
        XCTAssertTrue(mockWidgetSync.syncDownloadsCalled)
    }

    func testDeleteTaskClearsSelection() async {
        sut = makeSUT()
        let task = makeSampleTask(id: "1")
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task], isFromCache: false))
        await sut.fetchTasks()
        sut.selectedTask = task

        await sut.deleteTask(task)

        XCTAssertNil(sut.selectedTask)
    }

    func testDeleteTaskError() async {
        sut = makeSUT()
        let task = makeSampleTask(id: "1")
        mockTaskService.deleteTasksError = DomainError.taskNotFound(TaskID("1"))

        await sut.deleteTask(task)

        XCTAssertNotNil(sut.currentError)
    }

    // MARK: - Toggle Pause

    func testTogglePauseDownloadingTask() async {
        sut = makeSUT()
        let task = makeSampleTask(status: .downloading)
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task], isFromCache: false))

        await sut.togglePause(task)

        XCTAssertTrue(mockTaskService.pauseTasksCalled)
    }

    func testTogglePausePausedTask() async {
        sut = makeSUT()
        let task = makeSampleTask(status: .paused)
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task], isFromCache: false))

        await sut.togglePause(task)

        XCTAssertTrue(mockTaskService.resumeTasksCalled)
    }

    // MARK: - Create Task

    func testCreateTaskFromURL() async throws {
        sut = makeSUT()
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))

        try await sut.createTask(url: "https://example.com/file.zip", destination: "/downloads")

        XCTAssertTrue(mockTaskService.createTaskCalled)
    }

    func testCreateTaskFromMagnet() async throws {
        sut = makeSUT()
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))

        try await sut.createTask(url: "magnet:?xt=urn:btih:abc123", destination: nil)

        XCTAssertTrue(mockTaskService.createTaskCalled)
    }

    func testCreateTaskInvalidURL() async {
        sut = makeSUT()
        do {
            try await sut.createTask(url: "", destination: nil)
            XCTFail("Should throw")
        } catch let error as DomainError {
            XCTAssertEqual(error, .invalidDownloadURL)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCreateTaskFromTorrentFile() async throws {
        sut = makeSUT()
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))

        try await sut.createTask(fileData: Data("torrent".utf8), fileName: "test.torrent", destination: "/downloads")

        XCTAssertTrue(mockTaskService.createTaskCalled)
    }

    // MARK: - Filtering

    func testVisibleTasksNoFilter() async {
        sut = makeSUT()
        let tasks = [
            makeSampleTask(id: "1", title: "Alpha"),
            makeSampleTask(id: "2", title: "Beta")
        ]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))
        await sut.fetchTasks()

        XCTAssertEqual(sut.visibleTasks.count, 2)
    }

    func testVisibleTasksSearchFilter() async {
        sut = makeSUT()
        let tasks = [
            makeSampleTask(id: "1", title: "Alpha Download"),
            makeSampleTask(id: "2", title: "Beta Upload")
        ]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))
        await sut.fetchTasks()

        sut.searchText = "Alpha"

        XCTAssertEqual(sut.visibleTasks.count, 1)
        XCTAssertEqual(sut.visibleTasks.first?.title, "Alpha Download")
    }

    func testVisibleTasksStatusFilter() async {
        sut = makeSUT()
        let tasks = [
            makeSampleTask(id: "1", status: .downloading),
            makeSampleTask(id: "2", status: .finished),
            makeSampleTask(id: "3", status: .paused)
        ]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))
        await sut.fetchTasks()

        sut.statusFilter = .downloading
        XCTAssertEqual(sut.visibleTasks.count, 1)

        sut.statusFilter = .completed
        XCTAssertEqual(sut.visibleTasks.count, 1)

        sut.statusFilter = .paused
        XCTAssertEqual(sut.visibleTasks.count, 1)

        sut.statusFilter = .all
        XCTAssertEqual(sut.visibleTasks.count, 3)
    }

    func testClearAllFilters() async {
        sut = makeSUT()
        sut.searchText = "test"
        sut.statusFilter = .downloading
        sut.taskTypeFilter = .bt

        sut.clearAllFilters()

        XCTAssertEqual(sut.searchText, "")
        XCTAssertEqual(sut.taskTypeFilter, .all)
        XCTAssertEqual(sut.statusFilter, .all)
    }

    // MARK: - Refresh

    func testRefreshCallsForceRefresh() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))

        await sut.refresh()

        // refresh() calls fetchTasks(forceRefresh: true) which calls getTasks
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - TaskStatusPresentation

    func testStatusPresentationDownloading() {
        let presentation = TaskStatusPresentation(status: .downloading)
        XCTAssertEqual(presentation.color, .blue)
        XCTAssertFalse(presentation.text.isEmpty)
    }

    func testStatusPresentationFinished() {
        let presentation = TaskStatusPresentation(status: .finished)
        XCTAssertEqual(presentation.color, .green)
    }

    func testStatusPresentationSeeding() {
        let presentation = TaskStatusPresentation(status: .seeding)
        XCTAssertEqual(presentation.color, .green)
    }

    func testStatusPresentationPaused() {
        let presentation = TaskStatusPresentation(status: .paused)
        XCTAssertEqual(presentation.color, .orange)
    }

    func testStatusPresentationWaiting() {
        let presentation = TaskStatusPresentation(status: .waiting)
        XCTAssertEqual(presentation.color, .gray)
    }

    func testStatusPresentationError() {
        let presentation = TaskStatusPresentation(status: .error)
        XCTAssertEqual(presentation.color, .red)
    }

    func testStatusPresentationUnknown() {
        let presentation = TaskStatusPresentation(status: .unknown("custom_status"))
        XCTAssertEqual(presentation.color, .purple)
    }

    // MARK: - Toggle Pause Error

    func testTogglePauseError() async {
        sut = makeSUT()
        let task = makeSampleTask(status: .downloading)
        mockTaskService.pauseTasksError = DomainError.taskOperationFailed(TaskID("task-1"), reason: "fail")

        await sut.togglePause(task)

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Sorting

    func testSortByDownloadSpeed() async {
        sut = makeSUT()
        let task1 = DownloadTask(
            id: TaskID("1"), title: "Slow", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .megabytes(1), uploadSpeed: .zero)
        )
        let task2 = DownloadTask(
            id: TaskID("2"), title: "Fast", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .megabytes(10), uploadSpeed: .zero)
        )
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task1, task2], isFromCache: false))
        await sut.fetchTasks()

        sut.sortKey = .downloadSpeed
        sut.sortDirection = .descending

        XCTAssertEqual(sut.visibleTasks.first?.title, "Fast")
        XCTAssertEqual(sut.visibleTasks.last?.title, "Slow")
    }

    func testSortByUploadSpeed() async {
        sut = makeSUT()
        let task1 = DownloadTask(
            id: TaskID("1"), title: "LowUp", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .zero, uploadSpeed: .megabytes(1))
        )
        let task2 = DownloadTask(
            id: TaskID("2"), title: "HighUp", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .zero, uploadSpeed: .megabytes(10))
        )
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task1, task2], isFromCache: false))
        await sut.fetchTasks()

        sut.sortKey = .uploadSpeed
        sut.sortDirection = .descending

        XCTAssertEqual(sut.visibleTasks.first?.title, "HighUp")
    }

    func testSortByDownloadSpeedEqualFallsBackToName() async {
        sut = makeSUT()
        let task1 = DownloadTask(
            id: TaskID("1"), title: "Zebra", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .megabytes(5), uploadSpeed: .zero)
        )
        let task2 = DownloadTask(
            id: TaskID("2"), title: "Apple", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .megabytes(5), uploadSpeed: .zero)
        )
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task1, task2], isFromCache: false))
        await sut.fetchTasks()

        sut.sortKey = .downloadSpeed
        sut.sortDirection = .ascending

        // Equal speeds should fall back to name sorting
        XCTAssertEqual(sut.visibleTasks.first?.title, "Apple")
    }

    func testSortByUploadSpeedEqualFallsBackToName() async {
        sut = makeSUT()
        let task1 = DownloadTask(
            id: TaskID("1"), title: "Zebra", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .zero, uploadSpeed: .megabytes(5))
        )
        let task2 = DownloadTask(
            id: TaskID("2"), title: "Apple", size: .zero, status: .downloading, type: .bt, username: "admin",
            detail: TaskDetail(destination: "/"),
            transfer: TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .zero, uploadSpeed: .megabytes(5))
        )
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [task1, task2], isFromCache: false))
        await sut.fetchTasks()

        sut.sortKey = .uploadSpeed
        sut.sortDirection = .ascending

        XCTAssertEqual(sut.visibleTasks.first?.title, "Apple")
    }

    func testSortByName() async {
        sut = makeSUT()
        let tasks = [
            makeSampleTask(id: "1", title: "Zebra"),
            makeSampleTask(id: "2", title: "Apple")
        ]
        mockTaskService.getTasksResult = .success(TasksResult(tasks: tasks, isFromCache: false))
        await sut.fetchTasks()

        sut.sortKey = .name
        sut.sortDirection = .ascending

        XCTAssertEqual(sut.visibleTasks.first?.title, "Apple")
        XCTAssertEqual(sut.visibleTasks.last?.title, "Zebra")
    }

    // MARK: - Import Torrent File

    func testImportTorrentFileSuccess() throws {
        sut = makeSUT()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.torrent")
        try Data("fake torrent data".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let result = try sut.importTorrentFile(from: tempURL)

        XCTAssertEqual(result.name, "test.torrent")
        XCTAssertFalse(result.data.isEmpty)
    }

    func testImportTorrentFileNotFound() {
        sut = makeSUT()
        let badURL = URL(fileURLWithPath: "/nonexistent/path/file.torrent")

        XCTAssertThrowsError(try sut.importTorrentFile(from: badURL))
    }

    // MARK: - Domain Error Handling Branches

    func testFetchTasksOTPRequiredError() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .failure(DomainError.otpRequired)

        await sut.fetchTasks()

        XCTAssertNotNil(sut.currentError)
    }

    func testFetchTasksOTPInvalidError() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .failure(DomainError.otpInvalid)

        await sut.fetchTasks()

        XCTAssertNotNil(sut.currentError)
    }

    func testFetchTasksAPIError() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .failure(DomainError.apiError(code: 119, message: "SID expired"))

        await sut.fetchTasks()

        XCTAssertNotNil(sut.currentError)
    }

    // MARK: - Start/Stop Auto Refresh

    func testStartAutoRefreshCreatesTimer() {
        sut = makeSUT()
        sut.startAutoRefresh()
        // No crash, timer started. Stop immediately.
        sut.stopAutoRefresh()
    }

    func testStopAutoRefresh() {
        sut = makeSUT()
        sut.startAutoRefresh()
        sut.stopAutoRefresh()
        // Double stop should be safe
        sut.stopAutoRefresh()
    }
}
