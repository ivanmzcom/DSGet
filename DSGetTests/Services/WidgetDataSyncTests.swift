import XCTest
@testable import DSGetCore

// MARK: - Tests

final class WidgetDataSyncTests: XCTestCase {

    // MARK: - DownloadTask Model Tests (used by WidgetDataSync)

    private func makeTask(
        id: String = "task-1",
        title: String = "Test File",
        status: TaskStatus = .downloading,
        sizeBytes: Int64 = 1_000_000_000,
        downloadedBytes: Int64 = 500_000_000,
        downloadSpeed: Int64 = 5_242_880,
        uploadSpeed: Int64 = 1_048_576
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
                uploaded: ByteSize(bytes: 100_000_000),
                downloadSpeed: ByteSize(bytes: downloadSpeed),
                uploadSpeed: ByteSize(bytes: uploadSpeed)
            )
        )
    }

    // MARK: - Task Progress Tests

    func testTaskProgressCalculation() {
        let task = makeTask(sizeBytes: 1000, downloadedBytes: 500)
        XCTAssertEqual(task.progress, 0.5, accuracy: 0.01)
    }

    func testTaskProgressZeroSize() {
        let task = DownloadTask(
            id: TaskID("zero"),
            title: "Zero",
            size: .zero,
            status: .downloading,
            type: .http,
            username: "admin"
        )
        XCTAssertEqual(task.progress, 0.0)
    }

    func testTaskProgressComplete() {
        let task = makeTask(sizeBytes: 1000, downloadedBytes: 1000)
        XCTAssertEqual(task.progress, 1.0, accuracy: 0.01)
    }

    func testTaskProgressNoTransfer() {
        let task = DownloadTask(
            id: TaskID("no-transfer"),
            title: "No Transfer",
            size: .gigabytes(1),
            status: .waiting,
            type: .bt,
            username: "admin"
        )
        XCTAssertEqual(task.progress, 0.0)
    }

    // MARK: - Task Status Mapping Tests

    func testDownloadingStatus() {
        let task = makeTask(status: .downloading)
        XCTAssertTrue(task.isDownloading)
        XCTAssertFalse(task.isPaused)
        XCTAssertFalse(task.isCompleted)
    }

    func testPausedStatus() {
        let task = makeTask(status: .paused)
        XCTAssertTrue(task.isPaused)
        XCTAssertFalse(task.isDownloading)
        XCTAssertFalse(task.isCompleted)
    }

    func testFinishedStatus() {
        let task = makeTask(status: .finished)
        XCTAssertTrue(task.isCompleted)
        XCTAssertFalse(task.isDownloading)
    }

    func testSeedingStatus() {
        let task = makeTask(status: .seeding)
        XCTAssertTrue(task.isCompleted)
    }

    func testErrorStatus() {
        let task = makeTask(status: .error)
        XCTAssertTrue(task.hasError)
        XCTAssertFalse(task.isCompleted)
    }

    func testWaitingStatus() {
        let task = makeTask(status: .waiting)
        XCTAssertFalse(task.isDownloading)
        XCTAssertFalse(task.isCompleted)
        XCTAssertFalse(task.hasError)
    }

    // MARK: - Task Transfer Info Tests

    func testDownloadSpeed() {
        let task = makeTask(downloadSpeed: 5_242_880)
        XCTAssertEqual(task.downloadSpeed.bytes, 5_242_880)
        XCTAssertFalse(task.downloadSpeed.isZero)
    }

    func testUploadSpeed() {
        let task = makeTask(uploadSpeed: 1_048_576)
        XCTAssertEqual(task.uploadSpeed.bytes, 1_048_576)
    }

    func testShareRatio() {
        let task = makeTask(sizeBytes: 1000, downloadedBytes: 500)
        // uploaded=100_000_000, downloaded=500 → ratio = 100_000_000/500 = 200_000
        XCTAssertTrue(task.shareRatio > 0)
    }

    func testEstimatedTimeRemaining() {
        let task = makeTask(sizeBytes: 10_000_000, downloadedBytes: 5_000_000, downloadSpeed: 1_000_000)
        // remaining = 5_000_000, speed = 1_000_000 → 5 seconds
        XCTAssertNotNil(task.estimatedTimeRemaining)
        XCTAssertEqual(task.estimatedTimeRemaining!, 5.0, accuracy: 0.1)
    }

    func testEstimatedTimeRemainingZeroSpeed() {
        let task = makeTask(downloadSpeed: 0)
        XCTAssertNil(task.estimatedTimeRemaining)
    }

    // MARK: - Task Metadata Tests

    func testTaskDestination() {
        let task = makeTask()
        XCTAssertEqual(task.destination, "/downloads")
    }

    func testTaskIsTorrent() {
        let task = makeTask()
        XCTAssertTrue(task.isTorrent)
    }

    func testTaskFileCount() {
        let task = makeTask()
        XCTAssertEqual(task.fileCount, 0)
    }

    // MARK: - Sorting Multiple Tasks Tests

    func testSortTasksByStatus() {
        let tasks = [
            makeTask(id: "1", status: .finished),
            makeTask(id: "2", status: .downloading),
            makeTask(id: "3", status: .paused),
            makeTask(id: "4", status: .error),
            makeTask(id: "5", status: .waiting)
        ]

        let active = tasks.filter { $0.status == .downloading || $0.status == .paused }
        let completed = tasks.filter { $0.isCompleted }
        let errors = tasks.filter { $0.hasError }

        XCTAssertEqual(active.count, 2)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(errors.count, 1)
    }

    func testFilterDownloadingTasks() {
        let tasks = [
            makeTask(id: "1", status: .downloading),
            makeTask(id: "2", status: .downloading),
            makeTask(id: "3", status: .finished),
            makeTask(id: "4", status: .paused)
        ]

        let downloading = tasks.filter { $0.isDownloading }
        XCTAssertEqual(downloading.count, 2)
    }
}
