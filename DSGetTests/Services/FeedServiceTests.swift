import XCTest
@testable import DSGetCore

// MARK: - Mock Feed Service

final class MockFeedService: FeedServiceProtocol, @unchecked Sendable {
    var getFeedsResult: Result<FeedsResult, Error> = .success(FeedsResult(feeds: [], isFromCache: false))
    var getFeedItemsResult: Result<PaginatedResult<RSSFeedItem>, Error> = .success(PaginatedResult(items: [], total: 0))
    var refreshFeedError: Error?

    var getFeedsCalled = false
    var getFeedItemsCalled = false
    var refreshFeedCalled = false
    var lastFeedID: FeedID?
    var lastPagination: PaginationRequest?
    var lastForceRefresh: Bool?

    func getFeeds(forceRefresh: Bool) async throws -> FeedsResult {
        getFeedsCalled = true
        lastForceRefresh = forceRefresh
        return try getFeedsResult.get()
    }

    func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem> {
        getFeedItemsCalled = true
        lastFeedID = feedID
        lastPagination = pagination
        return try getFeedItemsResult.get()
    }

    func refreshFeed(id: FeedID) async throws {
        refreshFeedCalled = true
        lastFeedID = id
        if let error = refreshFeedError { throw error }
    }
}

// MARK: - Tests

final class FeedServiceTests: XCTestCase {

    private var mockService: MockFeedService!

    override func setUp() {
        super.setUp()
        mockService = MockFeedService()
    }

    // MARK: - Helpers

    private func makeSampleFeed(id: String = "1", title: String = "Test Feed") -> RSSFeed {
        RSSFeed(
            id: FeedID(id),
            title: title,
            url: URL(string: "https://example.com/rss"),
            isUpdating: false,
            lastUpdate: Date()
        )
    }

    private func makeSampleFeedItem(id: String = "item-1", title: String = "Test Item") -> RSSFeedItem {
        RSSFeedItem(
            id: FeedItemID(id),
            title: title,
            downloadURL: URL(string: "magnet:?xt=urn:btih:abc123"),
            externalURL: URL(string: "https://example.com/item"),
            size: "1073741824",
            publishedDate: Date(),
            isNew: true
        )
    }

    // MARK: - GetFeeds Tests

    func testGetFeedsReturnsEmptyList() async throws {
        let result = try await mockService.getFeeds(forceRefresh: false)

        XCTAssertTrue(result.feeds.isEmpty)
        XCTAssertTrue(mockService.getFeedsCalled)
    }

    func testGetFeedsReturnsFeeds() async throws {
        let feeds = [makeSampleFeed(id: "1"), makeSampleFeed(id: "2"), makeSampleFeed(id: "3")]
        mockService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))

        let result = try await mockService.getFeeds(forceRefresh: true)

        XCTAssertEqual(result.feeds.count, 3)
        XCTAssertFalse(result.isFromCache)
    }

    func testGetFeedsFromCache() async throws {
        let feeds = [makeSampleFeed()]
        mockService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: true))

        let result = try await mockService.getFeeds(forceRefresh: false)

        XCTAssertTrue(result.isFromCache)
    }

    func testGetFeedsForceRefresh() async throws {
        _ = try await mockService.getFeeds(forceRefresh: true)

        XCTAssertEqual(mockService.lastForceRefresh, true)
    }

    func testGetFeedsThrowsNoConnection() async {
        mockService.getFeedsResult = .failure(DomainError.noConnection)

        do {
            _ = try await mockService.getFeeds(forceRefresh: false)
            XCTFail("Should throw")
        } catch let error as DomainError {
            XCTAssertEqual(error, .noConnection)
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - GetFeedItems Tests

    func testGetFeedItemsReturnsItems() async throws {
        let items = [makeSampleFeedItem(id: "1"), makeSampleFeedItem(id: "2")]
        mockService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 2))

        let result = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: nil)

        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(result.total, 2)
    }

    func testGetFeedItemsWithPagination() async throws {
        let pagination = PaginationRequest(offset: 10, limit: 20)
        mockService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 50, offset: 10, limit: 20))

        let result = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: pagination)

        XCTAssertEqual(mockService.lastPagination?.offset, 10)
        XCTAssertEqual(mockService.lastPagination?.limit, 20)
        XCTAssertTrue(result.hasMore)
    }

    func testGetFeedItemsStoresFeedID() async throws {
        _ = try await mockService.getFeedItems(feedID: FeedID("42"), pagination: nil)

        XCTAssertEqual(mockService.lastFeedID?.rawValue, "42")
    }

    func testGetFeedItemsEmpty() async throws {
        mockService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 0))

        let result = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: nil)

        XCTAssertTrue(result.items.isEmpty)
        XCTAssertEqual(result.total, 0)
    }

    func testGetFeedItemsThrowsError() async {
        mockService.getFeedItemsResult = .failure(DomainError.feedNotFound(FeedID("999")))

        do {
            _ = try await mockService.getFeedItems(feedID: FeedID("999"), pagination: nil)
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .feedNotFound(let id) = error {
                XCTAssertEqual(id.rawValue, "999")
            } else {
                XCTFail("Wrong error")
            }
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - RefreshFeed Tests

    func testRefreshFeedSuccess() async throws {
        try await mockService.refreshFeed(id: FeedID("1"))

        XCTAssertTrue(mockService.refreshFeedCalled)
        XCTAssertEqual(mockService.lastFeedID?.rawValue, "1")
    }

    func testRefreshFeedThrowsError() async {
        mockService.refreshFeedError = DomainError.feedRefreshFailed(FeedID("1"))

        do {
            try await mockService.refreshFeed(id: FeedID("1"))
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .feedRefreshFailed(let id) = error {
                XCTAssertEqual(id.rawValue, "1")
            } else {
                XCTFail("Wrong error")
            }
        } catch {
            XCTFail("Unexpected error")
        }
    }

    // MARK: - Pagination Tests

    func testPaginationHasMorePages() async throws {
        let items = Array(repeating: makeSampleFeedItem(), count: 20)
        mockService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 100, offset: 0, limit: 20))

        let result = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: nil)

        XCTAssertTrue(result.hasMore)
        XCTAssertEqual(result.totalPages, 5)
        XCTAssertEqual(result.currentPage, 0)
        XCTAssertTrue(result.isFirstPage)
        XCTAssertFalse(result.isLastPage)
    }

    func testGetFeedItemsNoPagination() async throws {
        _ = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: nil)
        XCTAssertNil(mockService.lastPagination)
    }

    func testGetFeedsNotFromCacheOnForceRefresh() async throws {
        let feeds = [makeSampleFeed()]
        mockService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))
        let result = try await mockService.getFeeds(forceRefresh: true)
        XCTAssertFalse(result.isFromCache)
    }

    func testRefreshFeedSetsCorrectID() async throws {
        try await mockService.refreshFeed(id: FeedID("77"))
        XCTAssertEqual(mockService.lastFeedID?.rawValue, "77")
    }

    func testGetFeedItemsWithLargePagination() async throws {
        let pagination = PaginationRequest(offset: 0, limit: 500)
        mockService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 1000, offset: 0, limit: 500))
        let result = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: pagination)
        XCTAssertTrue(result.hasMore)
        XCTAssertEqual(result.totalPages, 2)
    }

    func testPaginationLastPage() async throws {
        let items = Array(repeating: makeSampleFeedItem(), count: 10)
        mockService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 50, offset: 40, limit: 10))

        let result = try await mockService.getFeedItems(feedID: FeedID("1"), pagination: PaginationRequest(offset: 40, limit: 10))

        XCTAssertFalse(result.hasMore)
        XCTAssertTrue(result.isLastPage)
        XCTAssertFalse(result.isFirstPage)
    }
}
