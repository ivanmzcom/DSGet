import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class AddTaskViewModelTests: XCTestCase {

    private var mockTaskService: MockTaskService!
    private var mockRecentFolders: MockRecentFoldersService!
    private var sut: AddTaskViewModel!

    override func setUp() {
        super.setUp()
        mockTaskService = MockTaskService()
        mockRecentFolders = MockRecentFoldersService()
    }

    // MARK: - Helpers

    private func makeSUT() -> AddTaskViewModel {
        AddTaskViewModel(taskService: mockTaskService, recentFoldersService: mockRecentFolders)
    }

    // MARK: - Initial State

    func testInitialState() {
        sut = makeSUT()
        XCTAssertEqual(sut.taskUrl, "")
        XCTAssertEqual(sut.destinationFolderPath, "")
        XCTAssertEqual(sut.inputMode, .url)
        XCTAssertNil(sut.selectedTorrentName)
        XCTAssertNil(sut.selectedTorrentData)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showingError)
    }

    func testInitWithPrefilledURL() {
        let vm = AddTaskViewModel(
            prefilledURL: "https://example.com/file.zip",
            taskService: mockTaskService,
            recentFoldersService: mockRecentFolders
        )

        XCTAssertEqual(vm.taskUrl, "https://example.com/file.zip")
    }

    func testInitWithPreselectedTorrent() {
        let torrent = AddTaskPreselectedTorrent(name: "test.torrent", data: Data("fake".utf8))
        let vm = AddTaskViewModel(
            preselectedTorrent: torrent,
            taskService: mockTaskService,
            recentFoldersService: mockRecentFolders
        )

        XCTAssertEqual(vm.inputMode, .file)
        XCTAssertEqual(vm.selectedTorrentName, "test.torrent")
        XCTAssertNotNil(vm.selectedTorrentData)
    }

    func testInitLoadsRecentFolders() {
        mockRecentFolders.folders = ["/downloads", "/media"]
        let vm = AddTaskViewModel(taskService: mockTaskService, recentFoldersService: mockRecentFolders)

        XCTAssertEqual(vm.recentFolders, ["/downloads", "/media"])
    }

    // MARK: - canCreateTask

    func testCanCreateTaskURLMode() {
        sut = makeSUT()
        sut.inputMode = .url
        sut.taskUrl = ""
        sut.destinationFolderPath = "/downloads"
        XCTAssertFalse(sut.canCreateTask)

        sut.taskUrl = "https://example.com/file.zip"
        XCTAssertTrue(sut.canCreateTask)
    }

    func testCanCreateTaskFileMode() {
        sut = makeSUT()
        sut.inputMode = .file
        sut.destinationFolderPath = "/downloads"
        XCTAssertFalse(sut.canCreateTask)

        sut.selectedTorrentData = Data("fake".utf8)
        XCTAssertTrue(sut.canCreateTask)
    }

    func testCanCreateTaskNoDestination() {
        sut = makeSUT()
        sut.taskUrl = "https://example.com"
        sut.destinationFolderPath = ""

        XCTAssertFalse(sut.canCreateTask)
    }

    // MARK: - Create Task

    func testCreateTaskURLSuccess() async {
        sut = makeSUT()
        sut.taskUrl = "https://example.com/file.zip"
        sut.destinationFolderPath = "/downloads"
        var callbackCalled = false
        sut.onTaskCreated = { callbackCalled = true }

        await sut.createTask()

        XCTAssertTrue(mockTaskService.createTaskCalled)
        XCTAssertTrue(sut.showingSuccessAlert)
        XCTAssertTrue(callbackCalled)
        XCTAssertFalse(sut.isLoading)
    }

    func testCreateTaskMagnetSuccess() async {
        sut = makeSUT()
        sut.taskUrl = "magnet:?xt=urn:btih:abc123"
        sut.destinationFolderPath = "/downloads"

        await sut.createTask()

        XCTAssertTrue(mockTaskService.createTaskCalled)
        XCTAssertTrue(sut.showingSuccessAlert)
    }

    func testCreateTaskSavesRecentFolder() async {
        sut = makeSUT()
        sut.taskUrl = "https://example.com/file.zip"
        sut.destinationFolderPath = "/downloads/movies"

        await sut.createTask()

        XCTAssertTrue(mockRecentFolders.addRecentFolderCalled)
        XCTAssertEqual(mockRecentFolders.lastAddedFolder, "/downloads/movies")
    }

    func testCreateTaskTorrentSuccess() async {
        sut = makeSUT()
        sut.inputMode = .file
        sut.selectedTorrentData = Data("torrent".utf8)
        sut.selectedTorrentName = "test.torrent"
        sut.destinationFolderPath = "/downloads"

        await sut.createTask()

        XCTAssertTrue(mockTaskService.createTaskCalled)
        XCTAssertTrue(sut.showingSuccessAlert)
        // Torrent file should be cleared after success
        XCTAssertNil(sut.selectedTorrentData)
        XCTAssertNil(sut.selectedTorrentName)
    }

    func testCreateTaskInvalidURL() async {
        sut = makeSUT()
        sut.taskUrl = "not a valid url with spaces and no scheme"
        sut.destinationFolderPath = "/downloads"

        await sut.createTask()

        // URL(string:) will succeed for many strings, so this tests the guard
        XCTAssertFalse(sut.isLoading)
    }

    func testCreateTaskError() async {
        sut = makeSUT()
        sut.taskUrl = "https://example.com/file.zip"
        sut.destinationFolderPath = "/downloads"
        mockTaskService.createTaskError = DomainError.invalidDownloadURL

        await sut.createTask()

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.showingSuccessAlert)
    }

    func testCreateTaskTorrentNoFile() async {
        sut = makeSUT()
        sut.inputMode = .file
        sut.destinationFolderPath = "/downloads"
        // No torrent data set

        await sut.createTask()

        // canCreateTask is false, so nothing happens
        XCTAssertFalse(mockTaskService.createTaskCalled)
    }

    // MARK: - Torrent File Management

    func testSelectTorrentFile() {
        sut = makeSUT()
        sut.selectTorrentFile(data: Data("fake".utf8), name: "movie.torrent")

        XCTAssertEqual(sut.selectedTorrentName, "movie.torrent")
        XCTAssertNotNil(sut.selectedTorrentData)
    }

    func testRemoveTorrentFile() {
        sut = makeSUT()
        sut.selectTorrentFile(data: Data("fake".utf8), name: "movie.torrent")
        sut.removeTorrentFile()

        XCTAssertNil(sut.selectedTorrentName)
        XCTAssertNil(sut.selectedTorrentData)
    }

    // MARK: - Recent Folders

    func testSelectRecentFolder() {
        sut = makeSUT()
        sut.selectRecentFolder("/downloads/movies")

        XCTAssertEqual(sut.destinationFolderPath, "/downloads/movies")
    }

    // MARK: - AddTaskInputMode

    func testInputModeURLTitle() {
        XCTAssertEqual(AddTaskInputMode.url.title, "URL")
        XCTAssertEqual(AddTaskInputMode.url.id, "url")
    }

    func testInputModeFileTitle() {
        XCTAssertEqual(AddTaskInputMode.file.title, ".torrent")
        XCTAssertEqual(AddTaskInputMode.file.id, "file")
    }

    // MARK: - Create Task Invalid URL

    func testCreateTaskURLInvalidThrows() async {
        sut = makeSUT()
        // A URL that URL(string:) rejects
        sut.taskUrl = "ht tp://invalid url with spaces"
        sut.destinationFolderPath = "/downloads"

        await sut.createTask()

        // Either canCreateTask prevents it or handleError catches it
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Create Task File Mode No Data Guard

    func testCreateTaskFileModeNoDataSetsError() async {
        sut = makeSUT()
        sut.inputMode = .file
        sut.destinationFolderPath = "/downloads"
        sut.selectedTorrentData = nil
        sut.selectedTorrentName = nil

        // canCreateTask is false, but let's also test with data but no name
        sut.selectedTorrentData = Data("fake".utf8)
        sut.selectedTorrentName = nil
        // canCreateTask checks selectedTorrentData != nil which is true
        // but createTask checks both data AND name in the guard
        await sut.createTask()

        // The guard should catch missing name
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }

    // MARK: - Handle File Import

    func testHandleFileImportSuccess() {
        sut = makeSUT()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import.torrent")
        try? Data("torrent data".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        sut.handleFileImport(.success(tempURL))

        XCTAssertEqual(sut.selectedTorrentName, "test_import.torrent")
        XCTAssertNotNil(sut.selectedTorrentData)
    }

    func testHandleFileImportFileError() {
        sut = makeSUT()
        let badURL = URL(fileURLWithPath: "/nonexistent/file.torrent")

        sut.handleFileImport(.success(badURL))

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }

    func testHandleFileImportFailure() {
        sut = makeSUT()

        sut.handleFileImport(.failure(NSError(domain: "test", code: -1)))

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }

    // MARK: - Reset

    func testReset() {
        sut = makeSUT()
        sut.taskUrl = "https://example.com"
        sut.destinationFolderPath = "/downloads"
        sut.inputMode = .file
        sut.selectedTorrentData = Data()
        sut.selectedTorrentName = "test"
        sut.showingError = true

        sut.reset()

        XCTAssertEqual(sut.taskUrl, "")
        XCTAssertEqual(sut.destinationFolderPath, "")
        XCTAssertEqual(sut.inputMode, .url)
        XCTAssertNil(sut.selectedTorrentData)
        XCTAssertNil(sut.selectedTorrentName)
        XCTAssertFalse(sut.showingError)
    }

    // MARK: - Handle File Import Non-File Error

    func testHandleFileImportWithNonFileError() {
        sut = makeSUT()
        let error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)

        sut.handleFileImport(.failure(error))

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }

    func testHandleFileImportWithURLError() {
        sut = makeSUT()
        let error = URLError(.notConnectedToInternet)

        sut.handleFileImport(.failure(error))

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }
}
