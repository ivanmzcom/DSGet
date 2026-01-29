import XCTest
@testable import DSGetCore

final class DomainModelTests: XCTestCase {

    // MARK: - ByteSize Tests

    func testByteSizeZero() {
        XCTAssertEqual(ByteSize.zero.bytes, 0)
        XCTAssertTrue(ByteSize.zero.isZero)
    }

    func testByteSizeKilobytes() {
        let size = ByteSize.kilobytes(1)
        XCTAssertEqual(size.bytes, 1024)
        XCTAssertEqual(size.kilobytes, 1.0, accuracy: 0.01)
    }

    func testByteSizeMegabytes() {
        let size = ByteSize.megabytes(1)
        XCTAssertEqual(size.bytes, 1_048_576)
        XCTAssertEqual(size.megabytes, 1.0, accuracy: 0.01)
    }

    func testByteSizeGigabytes() {
        let size = ByteSize.gigabytes(1)
        XCTAssertEqual(size.bytes, 1_073_741_824)
        XCTAssertEqual(size.gigabytes, 1.0, accuracy: 0.01)
    }

    func testByteSizeArithmetic() {
        let a = ByteSize.megabytes(5)
        let b = ByteSize.megabytes(3)
        XCTAssertEqual((a + b).megabytes, 8.0, accuracy: 0.01)
        XCTAssertEqual((a - b).megabytes, 2.0, accuracy: 0.01)
    }

    func testByteSizeComparable() {
        XCTAssertTrue(ByteSize.megabytes(1) < ByteSize.gigabytes(1))
        XCTAssertTrue(ByteSize.gigabytes(2) > ByteSize.gigabytes(1))
    }

    func testByteSizeRatio() {
        let half = ByteSize.megabytes(50)
        let total = ByteSize.megabytes(100)
        XCTAssertEqual(half.ratio(to: total), 0.5, accuracy: 0.01)
    }

    func testByteSizeRatioZeroDenominator() {
        XCTAssertEqual(ByteSize.megabytes(1).ratio(to: .zero), 0.0)
    }

    // MARK: - TaskID Tests

    func testTaskIDEquality() {
        XCTAssertEqual(TaskID("abc"), TaskID("abc"))
        XCTAssertNotEqual(TaskID("abc"), TaskID("def"))
    }

    func testTaskIDStringLiteral() {
        let id: TaskID = "test-id"
        XCTAssertEqual(id.rawValue, "test-id")
    }

    func testTaskIDDescription() {
        XCTAssertEqual(TaskID("my-task").description, "my-task")
    }

    // MARK: - FeedID Tests

    func testFeedIDFromString() {
        let id = FeedID("42")
        XCTAssertEqual(id.rawValue, "42")
        XCTAssertEqual(id.numericValue, 42)
    }

    func testFeedIDFromInt() {
        let id = FeedID(7)
        XCTAssertEqual(id.rawValue, "7")
    }

    func testFeedIDNonNumeric() {
        let id = FeedID("abc")
        XCTAssertNil(id.numericValue)
    }

    // MARK: - ServerID Tests

    func testServerIDCreation() {
        let id = ServerID()
        XCTAssertFalse(id.uuidString.isEmpty)
    }

    func testServerIDFromUUIDString() {
        let uuid = UUID()
        let id = ServerID(uuidString: uuid.uuidString)
        XCTAssertNotNil(id)
        XCTAssertEqual(id?.rawValue, uuid)
    }

    func testServerIDInvalidUUIDString() {
        let id = ServerID(uuidString: "not-a-uuid")
        XCTAssertNil(id)
    }

    // MARK: - TaskStatus Tests

    func testTaskStatusFromAPI() {
        XCTAssertEqual(TaskStatus(apiValue: "downloading"), .downloading)
        XCTAssertEqual(TaskStatus(apiValue: "paused"), .paused)
        XCTAssertEqual(TaskStatus(apiValue: "finished"), .finished)
        XCTAssertEqual(TaskStatus(apiValue: "seeding"), .seeding)
        XCTAssertEqual(TaskStatus(apiValue: "error"), .error)
        XCTAssertEqual(TaskStatus(apiValue: "waiting"), .waiting)
        XCTAssertEqual(TaskStatus(apiValue: "hash_checking"), .hashChecking)
    }

    func testTaskStatusUnknown() {
        let status = TaskStatus(apiValue: "custom_status")
        if case .unknown(let value) = status {
            XCTAssertEqual(value, "custom_status")
        } else {
            XCTFail("Should be unknown")
        }
    }

    func testTaskStatusProperties() {
        XCTAssertTrue(TaskStatus.downloading.isActive)
        XCTAssertTrue(TaskStatus.downloading.canPause)
        XCTAssertFalse(TaskStatus.downloading.canResume)
        XCTAssertTrue(TaskStatus.paused.canResume)
        XCTAssertFalse(TaskStatus.paused.canPause)
        XCTAssertTrue(TaskStatus.finished.isCompleted)
        XCTAssertTrue(TaskStatus.seeding.isCompleted)
        XCTAssertTrue(TaskStatus.error.hasError)
    }

    // MARK: - TaskType Tests

    func testTaskTypeFromAPI() {
        XCTAssertEqual(TaskType(apiValue: "bt"), .bt)
        XCTAssertEqual(TaskType(apiValue: "http"), .http)
        XCTAssertEqual(TaskType(apiValue: "ftp"), .ftp)
        XCTAssertEqual(TaskType(apiValue: "nzb"), .nzb)
    }

    func testTaskTypeDisplayName() {
        XCTAssertEqual(TaskType.bt.displayName, "BitTorrent")
        XCTAssertEqual(TaskType.http.displayName, "HTTP")
    }

    // MARK: - ServerConfiguration Tests

    func testServerConfigurationHTTPS() {
        let config = ServerConfiguration.https(host: "nas.local")
        XCTAssertEqual(config.port, 5001)
        XCTAssertTrue(config.useHTTPS)
        XCTAssertEqual(config.scheme, "https")
    }

    func testServerConfigurationHTTP() {
        let config = ServerConfiguration.http(host: "nas.local")
        XCTAssertEqual(config.port, 5000)
        XCTAssertFalse(config.useHTTPS)
    }

    func testServerConfigurationBaseURL() {
        let config = ServerConfiguration(host: "192.168.1.100", port: 5001, useHTTPS: true)
        XCTAssertEqual(config.baseURL?.absoluteString, "https://192.168.1.100:5001")
    }

    func testServerConfigurationValidation() {
        XCTAssertTrue(ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true).isValid)
        XCTAssertFalse(ServerConfiguration(host: "", port: 5001, useHTTPS: true).isValid)
        XCTAssertFalse(ServerConfiguration(host: "nas.local", port: 0, useHTTPS: true).isValid)
        XCTAssertFalse(ServerConfiguration(host: "nas.local", port: 70000, useHTTPS: true).isValid)
    }

    // MARK: - Session Tests

    func testSessionIsValid() {
        let session = Session(sessionID: "abc123", serverConfiguration: .https(host: "nas.local"))
        XCTAssertTrue(session.isValid)
    }

    func testSessionIsInvalidWithEmptyID() {
        let session = Session(sessionID: "", serverConfiguration: .https(host: "nas.local"))
        XCTAssertFalse(session.isValid)
    }

    func testSessionMightBeExpired() {
        let old = Session(
            sessionID: "abc",
            serverConfiguration: .https(host: "nas.local"),
            createdAt: Date().addingTimeInterval(-48 * 3600)
        )
        XCTAssertTrue(old.mightBeExpired())
    }

    func testSessionNotExpired() {
        let fresh = Session(sessionID: "abc", serverConfiguration: .https(host: "nas.local"))
        XCTAssertFalse(fresh.mightBeExpired())
    }

    func testSessionServerInfo() {
        let session = Session(sessionID: "abc", serverConfiguration: ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true))
        XCTAssertEqual(session.serverInfo, "nas.local:5001")
    }

    // MARK: - Credentials Tests

    func testCredentialsWithOTP() {
        let creds = Credentials(username: "admin", password: "pass")
        let withOTP = creds.withOTP("123456")
        XCTAssertEqual(withOTP.otpCode, "123456")
        XCTAssertEqual(withOTP.username, "admin")
    }

    func testCredentialsWithoutOTP() {
        let creds = Credentials(username: "admin", password: "pass", otpCode: "123456")
        let withoutOTP = creds.withoutOTP()
        XCTAssertNil(withoutOTP.otpCode)
    }

    // MARK: - DomainError Tests

    func testDomainErrorCategories() {
        XCTAssertTrue(DomainError.notAuthenticated.requiresRelogin)
        XCTAssertTrue(DomainError.sessionExpired.requiresRelogin)
        XCTAssertTrue(DomainError.noConnection.isConnectivityError)
        XCTAssertTrue(DomainError.timeout.isConnectivityError)
        XCTAssertTrue(DomainError.timeout.isRecoverable)
        XCTAssertTrue(DomainError.noConnection.canUseCacheFallback)
    }

    // MARK: - Pagination Tests

    func testPaginationDefault() {
        let p = PaginationRequest.default
        XCTAssertEqual(p.offset, 0)
        XCTAssertEqual(p.limit, 50)
    }

    func testPaginationNext() {
        let p = PaginationRequest(offset: 0, limit: 20)
        let next = p.next()
        XCTAssertEqual(next.offset, 20)
        XCTAssertEqual(next.limit, 20)
    }

    func testPaginationPrevious() {
        let p = PaginationRequest(offset: 40, limit: 20)
        let prev = p.previous()
        XCTAssertEqual(prev.offset, 20)
    }

    func testPaginationPreviousClampedToZero() {
        let p = PaginationRequest(offset: 5, limit: 20)
        let prev = p.previous()
        XCTAssertEqual(prev.offset, 0)
    }

    // MARK: - RSSFeed Tests

    func testRSSFeedPreview() {
        let feed = RSSFeed.preview()
        XCTAssertEqual(feed.title, "Sample Feed")
        XCTAssertNotNil(feed.url)
    }

    func testRSSFeedRecentlyUpdated() {
        let feed = RSSFeed(id: FeedID("1"), title: "Test", url: nil, lastUpdate: Date())
        XCTAssertTrue(feed.isRecentlyUpdated)
    }

    func testRSSFeedNotRecentlyUpdated() {
        let feed = RSSFeed(id: FeedID("1"), title: "Test", url: nil, lastUpdate: Date().addingTimeInterval(-7200))
        XCTAssertFalse(feed.isRecentlyUpdated)
    }

    // MARK: - RSSFeedItem Tests

    func testFeedItemCanDownload() {
        let item = RSSFeedItem.preview()
        XCTAssertTrue(item.canDownload)
    }

    func testFeedItemCannotDownload() {
        let item = RSSFeedItem(id: FeedItemID("1"), title: "No URL", downloadURL: nil, externalURL: nil, size: nil, publishedDate: nil)
        XCTAssertFalse(item.canDownload)
    }

    func testFeedItemPreferredDownloadURL() {
        let downloadURL = URL(string: "magnet:?xt=test")!
        let item = RSSFeedItem(id: FeedItemID("1"), title: "Test", downloadURL: downloadURL, externalURL: URL(string: "https://example.com"), size: nil, publishedDate: nil)
        XCTAssertEqual(item.preferredDownloadURL, downloadURL)
    }

    func testFeedItemFallbackToExternalURL() {
        let externalURL = URL(string: "https://example.com")!
        let item = RSSFeedItem(id: FeedItemID("1"), title: "Test", downloadURL: nil, externalURL: externalURL, size: nil, publishedDate: nil)
        XCTAssertEqual(item.preferredDownloadURL, externalURL)
    }

    // MARK: - Server Tests

    func testServerCreate() {
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001, useHTTPS: true)
        XCTAssertEqual(server.name, "My NAS")
        XCTAssertTrue(server.isValid)
    }

    func testServerDisplayName() {
        let server = Server.create(name: "", host: "nas.local", port: 5001)
        XCTAssertEqual(server.displayName, "nas.local:5001")
    }

    func testServerValidation() {
        let invalid = Server.create(name: "", host: "nas.local", port: 5001)
        XCTAssertFalse(invalid.isValid)
        XCTAssertNotNil(invalid.validationError)
    }

    // MARK: - ServerColor Tests

    func testServerColorDefault() {
        XCTAssertEqual(ServerColor.default, .blue)
    }

    func testServerColorAllCases() {
        XCTAssertEqual(ServerColor.allCases.count, 8)
    }

    // MARK: - TaskTransferInfo Tests

    func testTransferInfoProgress() {
        let info = TaskTransferInfo(downloaded: .megabytes(50), uploaded: .zero, downloadSpeed: .megabytes(5), uploadSpeed: .zero)
        let progress = info.progress(totalSize: .megabytes(100))
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testTransferInfoShareRatio() {
        let info = TaskTransferInfo(downloaded: .megabytes(100), uploaded: .megabytes(50), downloadSpeed: .zero, uploadSpeed: .zero)
        XCTAssertEqual(info.shareRatio, 0.5, accuracy: 0.01)
    }

    func testTransferInfoIsDownloading() {
        let active = TaskTransferInfo(downloaded: .zero, uploaded: .zero, downloadSpeed: .megabytes(1), uploadSpeed: .zero)
        XCTAssertTrue(active.isDownloading)

        let idle = TaskTransferInfo.empty
        XCTAssertFalse(idle.isDownloading)
    }
}
