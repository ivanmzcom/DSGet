import XCTest
@testable import DSGetCore

// MARK: - Mock File Service

final class MockFileService: FileServiceProtocol, @unchecked Sendable {
    var getSharesResult: Result<[FileSystemItem], Error> = .success([])
    var getFolderContentsResult: Result<[FileSystemItem], Error> = .success([])
    var createFolderError: Error?

    var getSharesCalled = false
    var getFolderContentsCalled = false
    var createFolderCalled = false
    var lastFolderPath: String?
    var lastCreateParentPath: String?
    var lastCreateFolderName: String?

    func getShares() async throws -> [FileSystemItem] {
        getSharesCalled = true
        return try getSharesResult.get()
    }

    func getFolderContents(path: String) async throws -> [FileSystemItem] {
        getFolderContentsCalled = true
        lastFolderPath = path
        return try getFolderContentsResult.get()
    }

    func createFolder(parentPath: String, name: String) async throws {
        createFolderCalled = true
        lastCreateParentPath = parentPath
        lastCreateFolderName = name
        if let error = createFolderError { throw error }
    }
}

// MARK: - Tests

final class FileServiceTests: XCTestCase {

    private var mockService: MockFileService!

    override func setUp() {
        super.setUp()
        mockService = MockFileService()
    }

    // MARK: - Helpers

    private func makeFolder(name: String = "Downloads", path: String = "/volume1") -> FileSystemItem {
        FileSystemItem(name: name, path: path, isDirectory: true)
    }

    private func makeFile(name: String = "movie.mkv", path: String = "/volume1/Downloads") -> FileSystemItem {
        FileSystemItem(
            name: name,
            path: path,
            isDirectory: false,
            size: .gigabytes(4.5),
            modificationDate: Date()
        )
    }

    // MARK: - GetShares Tests

    func testGetSharesReturnsEmptyList() async throws {
        let shares = try await mockService.getShares()

        XCTAssertTrue(shares.isEmpty)
        XCTAssertTrue(mockService.getSharesCalled)
    }

    func testGetSharesReturnsShares() async throws {
        let items = [makeFolder(name: "homes"), makeFolder(name: "video"), makeFolder(name: "music")]
        mockService.getSharesResult = .success(items)

        let shares = try await mockService.getShares()

        XCTAssertEqual(shares.count, 3)
        XCTAssertTrue(shares.allSatisfy { $0.isDirectory })
    }

    func testGetSharesThrowsError() async {
        mockService.getSharesResult = .failure(DomainError.notAuthenticated)

        do {
            _ = try await mockService.getShares()
            XCTFail("Should throw")
        } catch let error as DomainError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - GetFolderContents Tests

    func testGetFolderContentsReturnsItems() async throws {
        let items = [makeFolder(name: "subfolder"), makeFile(name: "file.txt")]
        mockService.getFolderContentsResult = .success(items)

        let contents = try await mockService.getFolderContents(path: "/volume1/Downloads")

        XCTAssertEqual(contents.count, 2)
        XCTAssertEqual(mockService.lastFolderPath, "/volume1/Downloads")
    }

    func testGetFolderContentsEmpty() async throws {
        mockService.getFolderContentsResult = .success([])

        let contents = try await mockService.getFolderContents(path: "/volume1/empty")

        XCTAssertTrue(contents.isEmpty)
    }

    func testGetFolderContentsMixedTypes() async throws {
        let items = [
            makeFolder(name: "docs"),
            makeFile(name: "readme.txt"),
            makeFile(name: "photo.jpg"),
            makeFolder(name: "backup")
        ]
        mockService.getFolderContentsResult = .success(items)

        let contents = try await mockService.getFolderContents(path: "/volume1")

        let folders = contents.filter { $0.isDirectory }
        let files = contents.filter { $0.isFile }
        XCTAssertEqual(folders.count, 2)
        XCTAssertEqual(files.count, 2)
    }

    func testGetFolderContentsThrowsPathNotFound() async {
        mockService.getFolderContentsResult = .failure(DomainError.pathNotFound("/invalid"))

        do {
            _ = try await mockService.getFolderContents(path: "/invalid")
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .pathNotFound(let path) = error {
                XCTAssertEqual(path, "/invalid")
            } else {
                XCTFail("Wrong error")
            }
        } catch {
            XCTFail("Unexpected error")
        }
    }

    func testGetFolderContentsThrowsAccessDenied() async {
        mockService.getFolderContentsResult = .failure(DomainError.accessDenied(path: "/root"))

        do {
            _ = try await mockService.getFolderContents(path: "/root")
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .accessDenied(let path) = error {
                XCTAssertEqual(path, "/root")
            } else {
                XCTFail("Wrong error")
            }
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - CreateFolder Tests

    func testCreateFolderSuccess() async throws {
        try await mockService.createFolder(parentPath: "/volume1/Downloads", name: "NewFolder")

        XCTAssertTrue(mockService.createFolderCalled)
        XCTAssertEqual(mockService.lastCreateParentPath, "/volume1/Downloads")
        XCTAssertEqual(mockService.lastCreateFolderName, "NewFolder")
    }

    func testCreateFolderThrowsError() async {
        mockService.createFolderError = DomainError.folderCreationFailed(reason: "permission denied")

        do {
            try await mockService.createFolder(parentPath: "/volume1", name: "test")
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .folderCreationFailed(let reason) = error {
                XCTAssertEqual(reason, "permission denied")
            } else {
                XCTFail("Wrong error")
            }
        } catch {
            XCTFail("Unexpected error")
        }
    }

    func testCreateFolderWithSpecialCharacters() async throws {
        try await mockService.createFolder(parentPath: "/volume1", name: "Mi Carpeta (2024)")

        XCTAssertEqual(mockService.lastCreateFolderName, "Mi Carpeta (2024)")
    }

    // MARK: - FileSystemItem Tests

    func testFileSystemItemIsFile() {
        let file = makeFile()
        XCTAssertTrue(file.isFile)
        XCTAssertFalse(file.isDirectory)
    }

    func testFileSystemItemIsDirectory() {
        let folder = makeFolder()
        XCTAssertTrue(folder.isDirectory)
        XCTAssertFalse(folder.isFile)
    }

    func testFileSystemItemFileExtension() {
        let mkv = makeFile(name: "movie.mkv")
        XCTAssertEqual(mkv.fileExtension, "mkv")

        let torrent = makeFile(name: "file.torrent")
        XCTAssertEqual(torrent.fileExtension, "torrent")

        let folder = makeFolder()
        XCTAssertEqual(folder.fileExtension, "")
    }

    func testFileSystemItemParentPath() {
        let file = makeFile(name: "movie.mkv", path: "/volume1/Downloads")
        XCTAssertEqual(file.parentPath, "/volume1")
    }

    func testFileSystemItemFullPath() {
        let file = FileSystemItem(name: "test.txt", path: "/volume1/docs", isDirectory: false)
        XCTAssertEqual(file.fullPath, "/volume1/docs/test.txt")
    }

    func testGetSharesAllDirectories() async throws {
        let items = [makeFolder(name: "share1"), makeFolder(name: "share2")]
        mockService.getSharesResult = .success(items)
        let shares = try await mockService.getShares()
        XCTAssertTrue(shares.allSatisfy { $0.isDirectory })
    }

    func testFileSystemItemIconName() {
        XCTAssertEqual(makeFolder().iconName, "folder.fill")
        XCTAssertEqual(makeFile(name: "movie.mp4").iconName, "film")
        XCTAssertEqual(makeFile(name: "song.mp3").iconName, "music.note")
        XCTAssertEqual(makeFile(name: "photo.jpg").iconName, "photo")
        XCTAssertEqual(makeFile(name: "archive.zip").iconName, "doc.zipper")
        XCTAssertEqual(makeFile(name: "doc.pdf").iconName, "doc.fill")
        XCTAssertEqual(makeFile(name: "unknown.xyz").iconName, "doc")
    }
}
