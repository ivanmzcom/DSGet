import XCTest
@testable import DSGetDomain

final class TaskTests: XCTestCase {

    // MARK: - TaskID Tests

    func testTaskIDInit() {
        let id = TaskID("task-123")
        XCTAssertEqual(id.rawValue, "task-123")
    }

    func testTaskIDStringLiteral() {
        let id: TaskID = "task-456"
        XCTAssertEqual(id.rawValue, "task-456")
    }

    func testTaskIDEquality() {
        let id1 = TaskID("same")
        let id2 = TaskID("same")
        XCTAssertEqual(id1, id2)
    }

    func testTaskIDHashable() {
        let id1 = TaskID("task-1")
        let id2 = TaskID("task-2")
        var set = Set<TaskID>()
        set.insert(id1)
        set.insert(id2)
        XCTAssertEqual(set.count, 2)
    }

    // MARK: - TaskStatus Tests

    func testTaskStatusFromAPIValue() {
        XCTAssertEqual(TaskStatus(apiValue: "downloading"), .downloading)
        XCTAssertEqual(TaskStatus(apiValue: "paused"), .paused)
        XCTAssertEqual(TaskStatus(apiValue: "seeding"), .seeding)
        XCTAssertEqual(TaskStatus(apiValue: "finished"), .finished)
        XCTAssertEqual(TaskStatus(apiValue: "waiting"), .waiting)
        XCTAssertEqual(TaskStatus(apiValue: "error"), .error)
        XCTAssertEqual(TaskStatus(apiValue: "hash_checking"), .hashChecking)
        XCTAssertEqual(TaskStatus(apiValue: "extracting"), .extracting)
        // unknown values get wrapped with the original string
        if case .unknown(let value) = TaskStatus(apiValue: "unknown_value") {
            XCTAssertEqual(value, "unknown_value")
        } else {
            XCTFail("Expected unknown status")
        }
    }

    func testTaskStatusIsActive() {
        XCTAssertTrue(TaskStatus.downloading.isActive)
        XCTAssertTrue(TaskStatus.seeding.isActive)
        XCTAssertTrue(TaskStatus.extracting.isActive)
        XCTAssertFalse(TaskStatus.paused.isActive)
        XCTAssertFalse(TaskStatus.finished.isActive)
        XCTAssertFalse(TaskStatus.error.isActive)
    }

    func testTaskStatusCanPause() {
        XCTAssertTrue(TaskStatus.downloading.canPause)
        XCTAssertTrue(TaskStatus.seeding.canPause)
        XCTAssertFalse(TaskStatus.paused.canPause)
        XCTAssertFalse(TaskStatus.finished.canPause)
    }

    func testTaskStatusCanResume() {
        XCTAssertTrue(TaskStatus.paused.canResume)
        XCTAssertFalse(TaskStatus.error.canResume) // Only paused can resume
        XCTAssertFalse(TaskStatus.downloading.canResume)
        XCTAssertFalse(TaskStatus.finished.canResume)
    }

    // MARK: - TaskType Tests

    func testTaskTypeFromAPIValue() {
        XCTAssertEqual(TaskType(apiValue: "bt"), .bt)
        XCTAssertEqual(TaskType(apiValue: "http"), .http)
        XCTAssertEqual(TaskType(apiValue: "ftp"), .ftp)
        XCTAssertEqual(TaskType(apiValue: "nzb"), .nzb)
        XCTAssertEqual(TaskType(apiValue: "emule"), .emule)
        // unknown values get wrapped with the original string
        if case .unknown(let value) = TaskType(apiValue: "other") {
            XCTAssertEqual(value, "other")
        } else {
            XCTFail("Expected unknown type")
        }
    }

    func testTaskTypeDisplayName() {
        XCTAssertEqual(TaskType.bt.displayName, "BitTorrent")
        XCTAssertEqual(TaskType.http.displayName, "HTTP")
        XCTAssertEqual(TaskType.ftp.displayName, "FTP")
    }

    // MARK: - DownloadTask Tests

    func testDownloadTaskInit() {
        let task = createTestTask()
        XCTAssertEqual(task.id.rawValue, "task-1")
        XCTAssertEqual(task.title, "Test Download")
        XCTAssertEqual(task.size.bytes, 1024 * 1024 * 100) // 100 MB
        XCTAssertEqual(task.status, .downloading)
        XCTAssertEqual(task.type, .bt)
    }

    func testDownloadTaskProgress() {
        let task = createTestTask(
            size: .megabytes(100),
            downloaded: .megabytes(50)
        )
        XCTAssertEqual(task.progress, 0.5, accuracy: 0.001)
    }

    func testDownloadTaskProgressWithZeroSize() {
        let task = createTestTask(size: .zero, downloaded: .zero)
        XCTAssertEqual(task.progress, 0)
    }

    func testDownloadTaskIsDownloading() {
        let downloading = createTestTask(status: .downloading)
        let paused = createTestTask(status: .paused)

        XCTAssertTrue(downloading.isDownloading)
        XCTAssertFalse(paused.isDownloading)
    }

    func testDownloadTaskIsCompleted() {
        let finished = createTestTask(status: .finished)
        let seeding = createTestTask(status: .seeding)
        let downloading = createTestTask(status: .downloading)

        XCTAssertTrue(finished.isCompleted)
        XCTAssertTrue(seeding.isCompleted)
        XCTAssertFalse(downloading.isCompleted)
    }

    func testDownloadTaskHasError() {
        let error = createTestTask(status: .error)
        let downloading = createTestTask(status: .downloading)

        XCTAssertTrue(error.hasError)
        XCTAssertFalse(downloading.hasError)
    }

    func testDownloadTaskDownloadedSize() {
        let task = createTestTask(
            size: .megabytes(100),
            downloaded: .megabytes(30)
        )
        XCTAssertEqual(task.downloadedSize, ByteSize.megabytes(30))
    }

    // MARK: - Helper Methods

    private func createTestTask(
        id: String = "task-1",
        title: String = "Test Download",
        size: ByteSize = .megabytes(100),
        status: TaskStatus = .downloading,
        type: TaskType = .bt,
        downloaded: ByteSize = .zero
    ) -> DownloadTask {
        let transfer = TaskTransferInfo(
            downloaded: downloaded,
            uploaded: .zero,
            downloadSpeed: .kilobytes(500),
            uploadSpeed: .kilobytes(100)
        )

        return DownloadTask(
            id: TaskID(id),
            title: title,
            size: size,
            status: status,
            type: type,
            username: "user",
            detail: nil,
            transfer: transfer,
            files: [],
            trackers: []
        )
    }
}
