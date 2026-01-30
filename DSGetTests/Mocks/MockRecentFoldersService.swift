import Foundation
@testable import DSGet

@MainActor
final class MockRecentFoldersService: RecentFoldersManaging {
    var folders: [String] = []
    var addRecentFolderCalled = false
    var clearRecentFoldersCalled = false
    var lastAddedFolder: String?

    var recentFolders: [String] {
        folders
    }

    func addRecentFolder(_ path: String) {
        addRecentFolderCalled = true
        lastAddedFolder = path
        folders.removeAll { $0 == path }
        folders.insert(path, at: 0)
    }

    func clearRecentFolders() {
        clearRecentFoldersCalled = true
        folders.removeAll()
    }
}
