import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class TaskDetailViewModelTests: XCTestCase {

    private var mockTaskService: MockTaskService!
    private var sut: TaskDetailViewModel!

    override func setUp() {
        super.setUp()
        mockTaskService = MockTaskService()
    }

    private func makeSUT(status: TaskStatus = .downloading, type: TaskType = .bt) -> TaskDetailViewModel {
        let task = makeSampleTask(status: status, type: type)
        return TaskDetailViewModel(task: task, taskService: mockTaskService)
    }

    // MARK: - Helpers

    private func makeSampleTask(
        id: String = "task-1",
        status: TaskStatus = .downloading,
        type: TaskType = .bt
    ) -> DownloadTask {
        DownloadTask(
            id: TaskID(id),
            title: "Test Download",
            size: ByteSize(bytes: 1_073_741_824),
            status: status,
            type: type,
            username: "admin",
            detail: TaskDetail(destination: "/downloads"),
            transfer: TaskTransferInfo(
                downloaded: ByteSize(bytes: 536_870_912),
                uploaded: .zero,
                downloadSpeed: .megabytes(5),
                uploadSpeed: .megabytes(1)
            )
        )
    }

    // MARK: - Initial State

    func testInitialState() {
        sut = makeSUT()
        XCTAssertEqual(sut.task.id.rawValue, "task-1")
        XCTAssertFalse(sut.isProcessingAction)
        XCTAssertNil(sut.statusOverride)
        XCTAssertNil(sut.currentError)
    }

    // MARK: - Effective Status

    func testEffectiveStatusReturnsTaskStatus() {
        sut = makeSUT()
        XCTAssertEqual(sut.effectiveStatus, "downloading")
    }

    func testEffectiveStatusReturnsOverride() {
        sut = makeSUT()
        sut.statusOverride = "paused"
        XCTAssertEqual(sut.effectiveStatus, "paused")
    }

    // MARK: - Can Toggle Pause

    func testCanTogglePauseDownloading() {
        sut = makeSUT()
        XCTAssertTrue(sut.canTogglePause)
    }

    func testCanTogglePausePaused() {
        sut = makeSUT(status: .paused)
        XCTAssertTrue(sut.canTogglePause)
    }

    func testCanTogglePauseFinished() {
        sut = makeSUT(status: .finished)
        XCTAssertFalse(sut.canTogglePause)
    }

    func testCanTogglePauseError() {
        sut = makeSUT(status: .error)
        XCTAssertFalse(sut.canTogglePause)
    }

    func testCanTogglePauseWhileProcessing() {
        sut = makeSUT(status: .downloading)
        XCTAssertTrue(sut.canTogglePause)
    }

    // MARK: - Toggle Pause/Resume

    func testTogglePauseDownloadingTaskPauses() async {
        sut = makeSUT()
        var updatedCalled = false
        sut.onTaskUpdated = { updatedCalled = true }

        await sut.togglePauseResume()

        XCTAssertTrue(mockTaskService.pauseTasksCalled)
        XCTAssertEqual(sut.statusOverride, "paused")
        XCTAssertTrue(updatedCalled)
        XCTAssertFalse(sut.isProcessingAction)
    }

    func testTogglePausePausedTaskResumes() async {
        sut = makeSUT(status: .paused)
        var updatedCalled = false
        sut.onTaskUpdated = { updatedCalled = true }

        await sut.togglePauseResume()

        XCTAssertTrue(mockTaskService.resumeTasksCalled)
        XCTAssertEqual(sut.statusOverride, "downloading")
        XCTAssertTrue(updatedCalled)
    }

    func testTogglePauseError() async {
        sut = makeSUT()
        mockTaskService.pauseTasksError = DomainError.taskOperationFailed(TaskID("task-1"), reason: "fail")

        await sut.togglePauseResume()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isProcessingAction)
    }

    func testTogglePauseDoesNothingWhenNotAllowed() async {
        sut = makeSUT(status: .finished)

        await sut.togglePauseResume()

        XCTAssertFalse(mockTaskService.pauseTasksCalled)
        XCTAssertFalse(mockTaskService.resumeTasksCalled)
    }

    // MARK: - Delete Task

    func testDeleteTaskSuccess() async {
        sut = makeSUT()
        var updatedCalled = false
        var deletedCalled = false
        sut.onTaskUpdated = { updatedCalled = true }
        sut.onTaskDeleted = { deletedCalled = true }

        await sut.deleteTask()

        XCTAssertTrue(mockTaskService.deleteTasksCalled)
        XCTAssertEqual(mockTaskService.lastDeletedIDs?.first?.rawValue, "task-1")
        XCTAssertTrue(updatedCalled)
        XCTAssertTrue(deletedCalled)
        XCTAssertFalse(sut.isProcessingAction)
    }

    func testDeleteTaskError() async {
        sut = makeSUT()
        mockTaskService.deleteTasksError = DomainError.taskNotFound(TaskID("task-1"))

        await sut.deleteTask()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isProcessingAction)
    }

    // MARK: - Edit Destination

    func testEditDestinationSuccess() async {
        sut = makeSUT()
        var updatedCalled = false
        sut.onTaskUpdated = { updatedCalled = true }

        await sut.editDestination("/volume1/new-path")

        XCTAssertTrue(mockTaskService.editDestinationCalled)
        XCTAssertEqual(mockTaskService.lastEditedDestination, "/volume1/new-path")
        XCTAssertTrue(updatedCalled)
        XCTAssertFalse(sut.isProcessingAction)
    }

    func testEditDestinationError() async {
        sut = makeSUT()
        mockTaskService.editDestinationError = DomainError.taskOperationFailed(TaskID("task-1"), reason: "denied")

        await sut.editDestination("/path")

        XCTAssertNotNil(sut.currentError)
    }

    // MARK: - Update Task

    func testUpdateTask() {
        sut = makeSUT()
        let newTask = makeSampleTask(id: "task-1", status: .paused)
        sut.statusOverride = "some-override"

        sut.updateTask(newTask)

        XCTAssertEqual(sut.task.status, .paused)
        XCTAssertNil(sut.statusOverride)
    }

    // MARK: - Is Task Paused

    func testIsTaskPausedTrue() {
        sut = makeSUT(status: .paused)
        XCTAssertTrue(sut.isTaskPaused)
    }

    func testIsTaskPausedFalse() {
        sut = makeSUT()
        XCTAssertFalse(sut.isTaskPaused)
    }

    func testIsTaskPausedWithOverride() {
        sut = makeSUT()
        sut.statusOverride = "paused"
        XCTAssertTrue(sut.isTaskPaused)
    }
}
