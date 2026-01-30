import Foundation
@testable import DSGetCore
@testable import DSGet

@MainActor
final class MockWidgetDataSyncService: WidgetDataSyncProtocol {
    var syncDownloadsCalled = false
    var setConnectionErrorCalled = false
    var lastSyncedTasks: [DownloadTask] = []
    var stubbedLastUpdateDate: Date?
    var stubbedHasCachedData: Bool = false
    var stubbedIsRecentSync: Bool = false

    func syncDownloads(_ tasks: [DownloadTask]) {
        syncDownloadsCalled = true
        lastSyncedTasks = tasks
    }

    func setConnectionError() {
        setConnectionErrorCalled = true
    }

    func lastUpdateDate() -> Date? {
        stubbedLastUpdateDate
    }

    func hasCachedData() -> Bool {
        stubbedHasCachedData
    }

    func isRecentSync() -> Bool {
        stubbedIsRecentSync
    }
}
