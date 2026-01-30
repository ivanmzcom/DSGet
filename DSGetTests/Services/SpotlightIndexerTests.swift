import XCTest
import CoreSpotlight
@testable import DSGetCore
@testable import DSGet

@MainActor
final class SpotlightIndexerTests: XCTestCase {

    private var indexer: SpotlightIndexer!

    override func setUp() async throws {
        try await super.setUp()
        indexer = SpotlightIndexer.shared
    }

    override func tearDown() async throws {
        indexer.removeAllItems()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeSampleTask(
        id: String = "task-1",
        title: String = "Test Download",
        status: TaskStatus = .downloading,
        type: TaskType = .bt,
        sizeBytes: Int64 = 1_073_741_824,
        destination: String = "/downloads"
    ) -> DownloadTask {
        let downloaded = ByteSize(bytes: sizeBytes / 2)
        return DownloadTask(
            id: TaskID(id),
            title: title,
            size: ByteSize(bytes: sizeBytes),
            status: status,
            type: type,
            username: "admin",
            detail: TaskDetail(destination: destination),
            transfer: TaskTransferInfo(
                downloaded: downloaded,
                uploaded: .zero,
                downloadSpeed: .megabytes(1),
                uploadSpeed: .zero
            )
        )
    }

    // MARK: - Index Tasks

    func testIndexTasksDoesNotCrash() {
        let tasks = [
            makeSampleTask(id: "task-1", title: "Download 1"),
            makeSampleTask(id: "task-2", title: "Download 2"),
            makeSampleTask(id: "task-3", title: "Download 3")
        ]

        indexer.indexTasks(tasks)
    }

    func testIndexEmptyTasksDoesNotCrash() {
        indexer.indexTasks([])
    }

    // MARK: - Index Single Task

    func testIndexSingleTaskDoesNotCrash() {
        let task = makeSampleTask(id: "single-task", title: "Single Download")
        indexer.indexTask(task)
    }

    func testIndexTaskWithDifferentStatuses() {
        indexer.indexTask(makeSampleTask(id: "task-1", status: .downloading))
        indexer.indexTask(makeSampleTask(id: "task-2", status: .finished))
        indexer.indexTask(makeSampleTask(id: "task-3", status: .paused))
    }

    func testIndexTaskWithDifferentTypes() {
        indexer.indexTask(makeSampleTask(id: "task-1", type: .bt))
        indexer.indexTask(makeSampleTask(id: "task-2", type: .http))
        indexer.indexTask(makeSampleTask(id: "task-3", type: .emule))
    }

    // MARK: - Remove Task

    func testRemoveTaskDoesNotCrash() {
        let task = makeSampleTask(id: "remove-task", title: "To Remove")
        indexer.indexTask(task)
        indexer.removeTask(task)
    }

    func testRemoveNonExistentTaskDoesNotCrash() {
        let task = makeSampleTask(id: "non-existent", title: "Non-existent")
        indexer.removeTask(task)
    }

    // MARK: - Remove All Items

    func testRemoveAllItemsDoesNotCrash() {
        let tasks = [
            makeSampleTask(id: "task-1", title: "Download 1"),
            makeSampleTask(id: "task-2", title: "Download 2")
        ]
        indexer.indexTasks(tasks)
        indexer.removeAllItems()
    }

    func testRemoveAllItemsWhenEmpty() {
        indexer.removeAllItems()
    }

    // MARK: - Update Tasks

    func testUpdateTasksDoesNotCrash() {
        indexer.indexTasks([
            makeSampleTask(id: "task-1", title: "Download 1"),
            makeSampleTask(id: "task-2", title: "Download 2")
        ])

        indexer.updateTasks([
            makeSampleTask(id: "task-1", title: "Updated Download 1"),
            makeSampleTask(id: "task-3", title: "New Download 3")
        ])
    }

    func testUpdateTasksWithEmptyArray() {
        indexer.indexTasks([makeSampleTask(id: "task-1", title: "Download 1")])
        indexer.updateTasks([])
    }

    // MARK: - Task ID from User Activity

    func testTaskIDFromUserActivityReturnsNilForWrongActivityType() {
        let userActivity = NSUserActivity(activityType: "com.example.wrongType")
        XCTAssertNil(indexer.taskID(from: userActivity))
    }

    func testTaskIDFromUserActivityReturnsNilWithoutIdentifier() {
        let userActivity = NSUserActivity(activityType: CSSearchableItemActionType)
        XCTAssertNil(indexer.taskID(from: userActivity))
    }

    func testTaskIDFromValidUserActivity() {
        let userActivity = NSUserActivity(activityType: CSSearchableItemActionType)
        userActivity.userInfo = [CSSearchableItemActivityIdentifier: "task-123"]
        XCTAssertEqual(indexer.taskID(from: userActivity), "task-123")
    }

    func testTaskIDFromUserActivityWithNonStringIdentifier() {
        let userActivity = NSUserActivity(activityType: CSSearchableItemActionType)
        userActivity.userInfo = [CSSearchableItemActivityIdentifier: 123]
        XCTAssertNil(indexer.taskID(from: userActivity))
    }

    // MARK: - Singleton

    func testSharedInstanceIsSingleton() {
        XCTAssertTrue(SpotlightIndexer.shared === SpotlightIndexer.shared)
    }

    // MARK: - Build Keywords and Description (Indirect Tests)

    func testIndexTaskWithVariousContentDoesNotCrash() {
        indexer.indexTask(makeSampleTask(
            id: "task-long",
            title: "Very Long Title With Many Words To Extract Keywords From Download"
        ))
        indexer.indexTask(makeSampleTask(
            id: "task-special",
            title: "Download [2024] - Movie.mkv (1080p)"
        ))
        indexer.indexTask(makeSampleTask(id: "task-nosize", sizeBytes: 0))
    }

    func testIndexTaskWithEmptyDestination() {
        indexer.indexTask(makeSampleTask(id: "task-no-dest", destination: ""))
    }

    func testIndexTaskWithLargeSize() {
        indexer.indexTask(makeSampleTask(id: "task-large", sizeBytes: 1_099_511_627_776))
    }

    // MARK: - Integration Test

    func testFullIndexingCycle() {
        let tasks = [
            makeSampleTask(id: "cycle-1", title: "First Task"),
            makeSampleTask(id: "cycle-2", title: "Second Task")
        ]
        indexer.indexTasks(tasks)
        indexer.indexTask(makeSampleTask(id: "cycle-1", title: "Updated First Task", status: .finished))
        indexer.removeTask(tasks[1])
        indexer.updateTasks([makeSampleTask(id: "cycle-3", title: "Third Task")])
        indexer.removeAllItems()
    }
}
