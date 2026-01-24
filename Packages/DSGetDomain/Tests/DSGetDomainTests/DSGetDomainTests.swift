import XCTest
@testable import DSGetDomain

final class DSGetDomainTests: XCTestCase {

    // MARK: - ByteSize Tests

    func testByteSizeFromBytes() {
        let size = ByteSize(bytes: 1024)
        XCTAssertEqual(size.bytes, 1024)
        XCTAssertEqual(size.kilobytes, 1.0)
    }

    func testByteSizeFromKilobytes() {
        let size = ByteSize.kilobytes(1.5)
        XCTAssertEqual(size.bytes, 1536)
    }

    func testByteSizeFromMegabytes() {
        let size = ByteSize.megabytes(1.0)
        XCTAssertEqual(size.bytes, 1024 * 1024)
    }

    func testByteSizeFromGigabytes() {
        let size = ByteSize.gigabytes(1.0)
        XCTAssertEqual(size.bytes, 1024 * 1024 * 1024)
    }

    func testByteSizeComparable() {
        let small = ByteSize.megabytes(1)
        let large = ByteSize.gigabytes(1)
        XCTAssertTrue(small < large)
    }

    func testByteSizeArithmetic() {
        let a = ByteSize(bytes: 100)
        let b = ByteSize(bytes: 50)
        XCTAssertEqual((a + b).bytes, 150)
        XCTAssertEqual((a - b).bytes, 50)
    }

    // MARK: - TaskStatus Tests

    func testTaskStatusFromAPIValue() {
        XCTAssertEqual(TaskStatus(apiValue: "downloading"), .downloading)
        XCTAssertEqual(TaskStatus(apiValue: "paused"), .paused)
        XCTAssertEqual(TaskStatus(apiValue: "finished"), .finished)
        XCTAssertEqual(TaskStatus(apiValue: "seeding"), .seeding)
        XCTAssertEqual(TaskStatus(apiValue: "unknown_value"), .unknown("unknown_value"))
    }

    func testTaskStatusIsActive() {
        XCTAssertTrue(TaskStatus.downloading.isActive)
        XCTAssertTrue(TaskStatus.seeding.isActive)
        XCTAssertFalse(TaskStatus.paused.isActive)
        XCTAssertFalse(TaskStatus.finished.isActive)
    }

    func testTaskStatusCanPause() {
        XCTAssertTrue(TaskStatus.downloading.canPause)
        XCTAssertFalse(TaskStatus.paused.canPause)
        XCTAssertFalse(TaskStatus.finished.canPause)
    }

    func testTaskStatusCanResume() {
        XCTAssertTrue(TaskStatus.paused.canResume)
        XCTAssertFalse(TaskStatus.downloading.canResume)
    }

    // MARK: - TaskType Tests

    func testTaskTypeFromAPIValue() {
        XCTAssertEqual(TaskType(apiValue: "bt"), .bt)
        XCTAssertEqual(TaskType(apiValue: "http"), .http)
        XCTAssertEqual(TaskType(apiValue: "ftp"), .ftp)
        XCTAssertEqual(TaskType(apiValue: "emule"), .emule)
    }

    // MARK: - TaskID Tests

    func testTaskIDStringLiteral() {
        let id: TaskID = "test-123"
        XCTAssertEqual(id.rawValue, "test-123")
    }

    // MARK: - DomainError Tests

    func testDomainErrorRequiresRelogin() {
        XCTAssertTrue(DomainError.sessionExpired.requiresRelogin)
        XCTAssertTrue(DomainError.notAuthenticated.requiresRelogin)
        XCTAssertFalse(DomainError.noConnection.requiresRelogin)
    }

    func testDomainErrorIsConnectivityError() {
        XCTAssertTrue(DomainError.noConnection.isConnectivityError)
        XCTAssertTrue(DomainError.timeout.isConnectivityError)
        XCTAssertFalse(DomainError.sessionExpired.isConnectivityError)
    }

    // MARK: - ServerConfiguration Tests

    func testServerConfigurationBaseURL() {
        let config = ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        XCTAssertEqual(config.baseURL?.absoluteString, "https://nas.local:5001")
    }

    func testServerConfigurationValidation() {
        let validConfig = ServerConfiguration(host: "nas.local", port: 5001)
        XCTAssertTrue(validConfig.isValid)

        let invalidConfig = ServerConfiguration(host: "", port: 5001)
        XCTAssertFalse(invalidConfig.isValid)
    }

    // MARK: - Pagination Tests

    func testPaginationRequest() {
        let request = PaginationRequest(offset: 0, limit: 50)
        XCTAssertEqual(request.offset, 0)
        XCTAssertEqual(request.limit, 50)

        let next = request.next()
        XCTAssertEqual(next.offset, 50)
        XCTAssertEqual(next.limit, 50)
    }

    func testPaginatedResultHasMore() {
        let result = PaginatedResult(items: [1, 2, 3], total: 10, offset: 0)
        XCTAssertTrue(result.hasMore)

        let lastPage = PaginatedResult(items: [8, 9, 10], total: 10, offset: 7)
        XCTAssertFalse(lastPage.hasMore)
    }
}
