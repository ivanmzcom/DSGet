import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class FolderPickerViewModelTests: XCTestCase {

    private var mockFileService: MockFileService!
    private var sut: FolderPickerViewModel!

    override func setUp() {
        super.setUp()
        mockFileService = MockFileService()
    }

    // MARK: - Helpers

    private func makeSUT(currentPath: String = "/") -> FolderPickerViewModel {
        FolderPickerViewModel(currentPath: currentPath, fileService: mockFileService)
    }

    private func makeFolder(name: String = "Downloads", path: String = "/volume1") -> FileSystemItem {
        FileSystemItem(name: name, path: path, isDirectory: true)
    }

    private func makeFile(name: String = "movie.mkv", path: String = "/volume1/Downloads") -> FileSystemItem {
        FileSystemItem(name: name, path: path, isDirectory: false, size: .gigabytes(4.5))
    }

    // MARK: - Initial State

    func testInitialState() {
        sut = makeSUT()
        XCTAssertEqual(sut.currentPath, "/")
        XCTAssertTrue(sut.isAtRoot)
        XCTAssertTrue(sut.folders.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isCreatingFolder)
    }

    func testInitWithCustomPath() {
        let vm = makeSUT(currentPath: "/volume1")
        XCTAssertEqual(vm.currentPath, "/volume1")
        XCTAssertFalse(vm.isAtRoot)
    }

    // MARK: - Load Folders

    func testLoadFoldersAtRoot() async {
        sut = makeSUT()
        let shares = [makeFolder(name: "homes"), makeFolder(name: "video")]
        mockFileService.getSharesResult = .success(shares)

        await sut.loadFolders()

        XCTAssertTrue(mockFileService.getSharesCalled)
        XCTAssertEqual(sut.folders.count, 2)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadFoldersAtPath() async {
        sut = makeSUT(currentPath: "/volume1")
        let items = [makeFolder(name: "docs"), makeFile(name: "file.txt"), makeFolder(name: "music")]
        mockFileService.getFolderContentsResult = .success(items)

        await sut.loadFolders()

        XCTAssertTrue(mockFileService.getFolderContentsCalled)
        // Only directories should be shown
        XCTAssertEqual(sut.folders.count, 2)
        XCTAssertTrue(sut.folders.allSatisfy { $0.isDirectory })
    }

    func testLoadFoldersSortsByName() async {
        sut = makeSUT()
        let folders = [makeFolder(name: "Zeta", path: "/z"), makeFolder(name: "Alpha", path: "/a")]
        mockFileService.getSharesResult = .success(folders)

        await sut.loadFolders()

        XCTAssertEqual(sut.folders.first?.name, "Alpha")
        XCTAssertEqual(sut.folders.last?.name, "Zeta")
    }

    func testLoadFoldersError() async {
        sut = makeSUT()
        mockFileService.getSharesResult = .failure(DomainError.notAuthenticated)

        await sut.loadFolders()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadFoldersWithDifferentPath() async {
        sut = makeSUT()
        let folders = [makeFolder(name: "subfolder")]
        mockFileService.getFolderContentsResult = .success(folders)

        await sut.loadFolders(path: "/volume1/downloads")

        XCTAssertEqual(sut.currentPath, "/volume1/downloads")
    }

    // MARK: - Navigate To

    func testNavigateToFolder() async {
        sut = makeSUT()
        let folder = makeFolder(name: "downloads", path: "/volume1/downloads")
        mockFileService.getFolderContentsResult = .success([])

        await sut.navigateTo(folder)

        XCTAssertEqual(sut.currentPath, "/volume1/downloads")
    }

    func testNavigateToFileDoesNothing() async {
        sut = makeSUT()
        let file = makeFile()

        await sut.navigateTo(file)

        XCTAssertEqual(sut.currentPath, "/")
    }

    // MARK: - Create Folder

    func testCreateFolderSuccess() async {
        sut = makeSUT(currentPath: "/volume1")
        sut.newFolderName = "NewFolder"
        mockFileService.getFolderContentsResult = .success([])

        await sut.createFolder()

        XCTAssertTrue(mockFileService.createFolderCalled)
        XCTAssertEqual(mockFileService.lastCreateParentPath, "/volume1")
        XCTAssertEqual(mockFileService.lastCreateFolderName, "NewFolder")
        XCTAssertEqual(sut.newFolderName, "")
        XCTAssertFalse(sut.showingCreateFolder)
        XCTAssertFalse(sut.isCreatingFolder)
    }

    func testCreateFolderAtRootFails() async {
        sut = makeSUT()
        sut.newFolderName = "NewFolder"

        await sut.createFolder()

        XCTAssertFalse(mockFileService.createFolderCalled)
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }

    func testCreateFolderEmptyNameSkips() async {
        sut = makeSUT(currentPath: "/volume1")
        sut.newFolderName = "   "

        await sut.createFolder()

        XCTAssertFalse(mockFileService.createFolderCalled)
    }

    func testCreateFolderError() async {
        sut = makeSUT(currentPath: "/volume1")
        sut.newFolderName = "NewFolder"
        mockFileService.createFolderError = DomainError.folderCreationFailed(reason: "denied")

        await sut.createFolder()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isCreatingFolder)
    }

    // MARK: - Computed Properties

    func testNavigationTitleAtRoot() {
        sut = makeSUT()
        XCTAssertEqual(sut.navigationTitle, "Shared Folders")
    }

    func testNavigationTitleAtPath() {
        sut = makeSUT(currentPath: "/volume1/Downloads")
        XCTAssertEqual(sut.navigationTitle, "Downloads")
    }

    func testCanSelectCurrentFolderAtRoot() {
        sut = makeSUT()
        XCTAssertFalse(sut.canSelectCurrentFolder)
    }

    func testCanSelectCurrentFolderAtPath() {
        sut = makeSUT(currentPath: "/volume1")
        XCTAssertTrue(sut.canSelectCurrentFolder)
    }

    func testCanCreateFolderAtRoot() {
        sut = makeSUT()
        XCTAssertFalse(sut.canCreateFolder)
    }

    func testCanCreateFolderAtPath() {
        sut = makeSUT(currentPath: "/volume1")
        XCTAssertTrue(sut.canCreateFolder)
    }

    // MARK: - Format Path

    func testFormatPathForSelection() {
        sut = makeSUT()
        XCTAssertEqual(sut.formatPathForSelection("/volume1/downloads"), "volume1/downloads")
        XCTAssertEqual(sut.formatPathForSelection("volume1"), "volume1")
    }

    // MARK: - Dismiss

    func testDismissCreateFolderSheet() {
        sut = makeSUT()
        sut.newFolderName = "test"
        sut.showingCreateFolder = true

        sut.dismissCreateFolderSheet()

        XCTAssertEqual(sut.newFolderName, "")
        XCTAssertFalse(sut.showingCreateFolder)
    }

    // MARK: - Subfolder ViewModel

    func testViewModelForSubfolder() {
        sut = makeSUT()
        let folder = makeFolder(name: "downloads", path: "/volume1/downloads")

        let subVM = sut.viewModelForSubfolder(folder)

        XCTAssertEqual(subVM.currentPath, "/volume1/downloads")
    }
}
