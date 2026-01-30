import XCTest
@testable import DSGet

@MainActor
final class RecentFoldersServiceTests: XCTestCase {

    private let suiteName = "RecentFoldersServiceTests"

    private func makeSUT() -> RecentFoldersService {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return RecentFoldersService(userDefaults: defaults)
    }

    // MARK: - Initial State

    func testInitiallyEmpty() {
        let sut = makeSUT()
        XCTAssertTrue(sut.recentFolders.isEmpty)
    }

    // MARK: - Add Folder

    func testAddFolder() {
        let sut = makeSUT()
        sut.addRecentFolder("/downloads")

        XCTAssertEqual(sut.recentFolders, ["/downloads"])
    }

    func testAddMultipleFolders() {
        let sut = makeSUT()
        sut.addRecentFolder("/downloads")
        sut.addRecentFolder("/media")

        XCTAssertEqual(sut.recentFolders, ["/media", "/downloads"])
    }

    func testAddDuplicateMovesToTop() {
        let sut = makeSUT()
        sut.addRecentFolder("/downloads")
        sut.addRecentFolder("/media")
        sut.addRecentFolder("/downloads")

        XCTAssertEqual(sut.recentFolders, ["/downloads", "/media"])
    }

    func testAddEmptyPathIgnored() {
        let sut = makeSUT()
        sut.addRecentFolder("")

        XCTAssertTrue(sut.recentFolders.isEmpty)
    }

    func testMaxRecentFoldersLimit() {
        let sut = makeSUT()
        for index in 0..<15 {
            sut.addRecentFolder("/folder\(index)")
        }

        XCTAssertEqual(sut.recentFolders.count, 10)
        XCTAssertEqual(sut.recentFolders.first, "/folder14")
    }

    // MARK: - Clear

    func testClearRecentFolders() {
        let sut = makeSUT()
        sut.addRecentFolder("/downloads")
        sut.addRecentFolder("/media")

        sut.clearRecentFolders()

        XCTAssertTrue(sut.recentFolders.isEmpty)
    }

    // MARK: - Persistence

    func testPersistsAcrossInstances() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        let sut1 = RecentFoldersService(userDefaults: defaults)
        sut1.addRecentFolder("/downloads")

        let sut2 = RecentFoldersService(userDefaults: defaults)
        XCTAssertEqual(sut2.recentFolders, ["/downloads"])
    }
}
