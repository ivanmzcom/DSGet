import XCTest
@testable import DSGetDomain

final class PaginationTests: XCTestCase {

    // MARK: - PaginationRequest Tests

    func testPaginationRequestDefault() {
        let request = PaginationRequest.default
        XCTAssertEqual(request.offset, 0)
        XCTAssertEqual(request.limit, 50)
    }

    func testPaginationRequestInit() {
        let request = PaginationRequest(offset: 10, limit: 25)
        XCTAssertEqual(request.offset, 10)
        XCTAssertEqual(request.limit, 25)
    }

    func testPaginationRequestNegativeValues() {
        let request = PaginationRequest(offset: -5, limit: -10)
        XCTAssertEqual(request.offset, 0) // Should be clamped to 0
        XCTAssertEqual(request.limit, 1) // Should be clamped to 1
    }

    func testPaginationRequestNext() {
        let request = PaginationRequest(offset: 0, limit: 20)
        let next = request.next()
        XCTAssertEqual(next.offset, 20)
        XCTAssertEqual(next.limit, 20)
    }

    func testPaginationRequestPrevious() {
        let request = PaginationRequest(offset: 40, limit: 20)
        let previous = request.previous()
        XCTAssertEqual(previous.offset, 20)
        XCTAssertEqual(previous.limit, 20)
    }

    func testPaginationRequestPreviousAtStart() {
        let request = PaginationRequest(offset: 10, limit: 20)
        let previous = request.previous()
        XCTAssertEqual(previous.offset, 0) // Clamped to 0
    }

    // MARK: - PaginatedResult Tests

    func testPaginatedResultInit() {
        let items = ["a", "b", "c"]
        let result = PaginatedResult(items: items, total: 100, offset: 0)

        XCTAssertEqual(result.items.count, 3)
        XCTAssertEqual(result.total, 100)
        XCTAssertEqual(result.offset, 0)
    }

    func testPaginatedResultHasMore() {
        let hasMore = PaginatedResult(items: [1, 2, 3], total: 100, offset: 0)
        XCTAssertTrue(hasMore.hasMore)

        let noMore = PaginatedResult(items: [1, 2, 3], total: 3, offset: 0)
        XCTAssertFalse(noMore.hasMore)

        let lastPage = PaginatedResult(items: [1, 2, 3], total: 10, offset: 7)
        XCTAssertFalse(lastPage.hasMore)
    }

    func testPaginatedResultCurrentPage() {
        let firstPage = PaginatedResult(items: Array(1...20), total: 100, offset: 0, limit: 20)
        XCTAssertEqual(firstPage.currentPage, 0)

        let secondPage = PaginatedResult(items: Array(1...20), total: 100, offset: 20, limit: 20)
        XCTAssertEqual(secondPage.currentPage, 1)

        let thirdPage = PaginatedResult(items: Array(1...20), total: 100, offset: 40, limit: 20)
        XCTAssertEqual(thirdPage.currentPage, 2)
    }

    func testPaginatedResultTotalPages() {
        let result1 = PaginatedResult(items: Array(1...20), total: 100, offset: 0, limit: 20)
        XCTAssertEqual(result1.totalPages, 5)

        let result2 = PaginatedResult(items: Array(1...20), total: 105, offset: 0, limit: 20)
        XCTAssertEqual(result2.totalPages, 6) // Ceiling division

        let empty = PaginatedResult<Int>(items: [], total: 0, offset: 0, limit: 20)
        XCTAssertEqual(empty.totalPages, 0)
    }
}
