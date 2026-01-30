import XCTest
import UIKit
@testable import DSGetCore
@testable import DSGet

@MainActor
final class QuickActionsHandlerTests: XCTestCase {

    // MARK: - QuickActionType

    func testQuickActionTypeRawValues() {
        XCTAssertEqual(QuickActionType.addTask.rawValue, "com.dsget.addTask")
        XCTAssertEqual(QuickActionType.viewDownloads.rawValue, "com.dsget.viewDownloads")
        XCTAssertEqual(QuickActionType.refresh.rawValue, "com.dsget.refresh")
    }

    func testQuickActionTypeTitles() {
        XCTAssertFalse(QuickActionType.addTask.title.isEmpty)
        XCTAssertFalse(QuickActionType.viewDownloads.title.isEmpty)
        XCTAssertFalse(QuickActionType.refresh.title.isEmpty)
    }

    func testQuickActionTypeSystemImages() {
        XCTAssertEqual(QuickActionType.addTask.systemImage, "plus.circle.fill")
        XCTAssertEqual(QuickActionType.viewDownloads.systemImage, "arrow.down.circle.fill")
        XCTAssertEqual(QuickActionType.refresh.systemImage, "arrow.clockwise")
    }

    // MARK: - Handle Shortcut Item

    func testHandleValidShortcutItem() {
        let handler = QuickActionsHandler.shared
        let item = UIApplicationShortcutItem(type: "com.dsget.addTask", localizedTitle: "Add")

        let result = handler.handleShortcutItem(item)

        XCTAssertTrue(result)
        XCTAssertEqual(handler.pendingAction, .addTask)

        // Clean up
        handler.pendingAction = nil
    }

    func testHandleInvalidShortcutItem() {
        let handler = QuickActionsHandler.shared
        let item = UIApplicationShortcutItem(type: "com.unknown.action", localizedTitle: "Unknown")

        let result = handler.handleShortcutItem(item)

        XCTAssertFalse(result)
    }

    // MARK: - Process Pending Action

    func testProcessPendingActionAddTask() {
        let handler = QuickActionsHandler.shared
        let appVM = makeAppViewModel()

        handler.pendingAction = .addTask
        handler.processPendingAction(appViewModel: appVM)

        XCTAssertTrue(appVM.isShowingAddTask)
        XCTAssertNil(handler.pendingAction)
    }

    func testProcessPendingActionViewDownloads() {
        let handler = QuickActionsHandler.shared
        let appVM = makeAppViewModel()

        handler.pendingAction = .viewDownloads
        handler.processPendingAction(appViewModel: appVM)

        XCTAssertNil(handler.pendingAction)
    }

    func testProcessPendingActionRefresh() {
        let handler = QuickActionsHandler.shared
        let appVM = makeAppViewModel()

        handler.pendingAction = .refresh
        handler.processPendingAction(appViewModel: appVM)

        XCTAssertNil(handler.pendingAction)
    }

    func testProcessNoPendingAction() {
        let handler = QuickActionsHandler.shared
        let appVM = makeAppViewModel()

        handler.pendingAction = nil
        handler.processPendingAction(appViewModel: appVM)

        XCTAssertFalse(appVM.isShowingAddTask)
    }

    // MARK: - Helpers

    private func makeAppViewModel() -> AppViewModel {
        let mockTaskService = MockTaskService()
        let mockFeedService = MockFeedService()
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [], isFromCache: false))

        return AppViewModel(
            tasksViewModel: TasksViewModel(taskService: mockTaskService, widgetSyncService: MockWidgetDataSyncService()),
            feedsViewModel: FeedsViewModel(feedService: mockFeedService),
            authService: MockAuthService(),
            connectivityService: MockConnectivityService()
        )
    }
}
