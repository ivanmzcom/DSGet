import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class FeedsViewModelTests: XCTestCase {

    private var mockFeedService: MockFeedService!
    private var sut: FeedsViewModel!

    override func setUp() {
        super.setUp()
        mockFeedService = MockFeedService()
    }

    // MARK: - Helpers

    private func makeSUT() -> FeedsViewModel {
        FeedsViewModel(feedService: mockFeedService)
    }

    private func makeFeed(id: String = "1", title: String = "Test Feed") -> RSSFeed {
        RSSFeed(
            id: FeedID(id),
            title: title,
            url: URL(string: "https://example.com/rss"),
            isUpdating: false,
            lastUpdate: Date()
        )
    }

    // MARK: - Fetch Feeds

    func testFetchFeedsSuccess() async {
        sut = makeSUT()
        let feeds = [makeFeed(id: "1", title: "Feed A"), makeFeed(id: "2", title: "Feed B")]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))

        await sut.fetchFeeds()

        XCTAssertEqual(sut.feeds.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isOfflineMode)
        XCTAssertNil(sut.currentError)
    }

    func testFetchFeedsSortsByTitle() async {
        sut = makeSUT()
        let feeds = [makeFeed(id: "1", title: "Zeta"), makeFeed(id: "2", title: "Alpha")]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))

        await sut.fetchFeeds()

        XCTAssertEqual(sut.feeds.first?.title, "Alpha")
        XCTAssertEqual(sut.feeds.last?.title, "Zeta")
    }

    func testFetchFeedsFromCache() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [makeFeed()], isFromCache: true))

        await sut.fetchFeeds()

        XCTAssertTrue(sut.isOfflineMode)
    }

    func testFetchFeedsError() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .failure(DomainError.noConnection)

        await sut.fetchFeeds()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isLoading)
    }

    func testFetchFeedsIfNeededSkipsWhenLoaded() async {
        sut = makeSUT()
        let feeds = [makeFeed()]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))
        await sut.fetchFeeds()
        mockFeedService.getFeedsCalled = false

        await sut.fetchFeedsIfNeeded()

        XCTAssertFalse(mockFeedService.getFeedsCalled)
    }

    func testFetchFeedsIfNeededLoadsWhenEmpty() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [makeFeed()], isFromCache: false))

        await sut.fetchFeedsIfNeeded()

        XCTAssertTrue(mockFeedService.getFeedsCalled)
    }

    // MARK: - Refresh

    func testRefreshCallsFetchWithForceRefresh() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [], isFromCache: false))

        await sut.refresh()

        XCTAssertEqual(mockFeedService.lastForceRefresh, true)
    }

    func testRefreshFeedSuccess() async {
        sut = makeSUT()
        let feed = makeFeed()
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [feed], isFromCache: false))

        await sut.refreshFeed(feed)

        XCTAssertTrue(mockFeedService.refreshFeedCalled)
        XCTAssertEqual(mockFeedService.lastFeedID, feed.id)
    }

    func testRefreshFeedError() async {
        sut = makeSUT()
        let feed = makeFeed()
        mockFeedService.refreshFeedError = DomainError.feedRefreshFailed(feed.id)
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [], isFromCache: false))

        await sut.refreshFeed(feed)

        XCTAssertNotNil(sut.currentError)
    }

    func testRefreshFeedCompletesAndAllowsAnother() async {
        sut = makeSUT()
        let feed = makeFeed()
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [feed], isFromCache: false))

        await sut.refreshFeed(feed)
        XCTAssertTrue(mockFeedService.refreshFeedCalled)

        // After completion, refreshingFeeds should be cleared
        XCTAssertFalse(sut.refreshingFeeds.contains(feed.id))
    }

    // MARK: - Search Filter

    func testVisibleFeedsNoFilter() async {
        sut = makeSUT()
        let feeds = [makeFeed(id: "1", title: "Alpha"), makeFeed(id: "2", title: "Beta")]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))
        await sut.fetchFeeds()

        XCTAssertEqual(sut.visibleFeeds.count, 2)
    }

    func testVisibleFeedsWithSearch() async {
        sut = makeSUT()
        let feeds = [makeFeed(id: "1", title: "Movies RSS"), makeFeed(id: "2", title: "Music Feed")]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))
        await sut.fetchFeeds()

        sut.searchText = "Movies"

        XCTAssertEqual(sut.visibleFeeds.count, 1)
        XCTAssertEqual(sut.visibleFeeds.first?.title, "Movies RSS")
    }

    // MARK: - Favorites

    func testToggleFavorite() {
        sut = makeSUT()
        let feed = makeFeed(id: "1")

        sut.toggleFavorite(feed)
        XCTAssertTrue(sut.isFavorite(feed))

        sut.toggleFavorite(feed)
        XCTAssertFalse(sut.isFavorite(feed))
    }

    func testFavoriteFeeds() async {
        sut = makeSUT()
        let feeds = [
            makeFeed(id: "1", title: "Alpha"),
            makeFeed(id: "2", title: "Beta"),
            makeFeed(id: "3", title: "Gamma")
        ]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))
        await sut.fetchFeeds()

        sut.toggleFavorite(feeds[0])
        sut.toggleFavorite(feeds[2])

        XCTAssertEqual(sut.favoriteFeeds.count, 2)
        XCTAssertEqual(sut.favoriteFeeds.first?.title, "Alpha")
        XCTAssertEqual(sut.favoriteFeeds.last?.title, "Gamma")
    }

    // MARK: - Selected Feed

    func testSelectedFeed() async {
        sut = makeSUT()
        let feeds = [makeFeed(id: "1", title: "Feed A"), makeFeed(id: "2", title: "Feed B")]
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: feeds, isFromCache: false))
        await sut.fetchFeeds()

        sut.selectedFeedID = FeedID("2")

        XCTAssertEqual(sut.selectedFeed?.title, "Feed B")
    }

    func testSelectedFeedNilWhenNoSelection() {
        sut = makeSUT()
        XCTAssertNil(sut.selectedFeed)
    }

    // MARK: - Refreshing State

    func testIsRefreshingFalseByDefault() {
        sut = makeSUT()
        let feed = makeFeed(id: "1")
        XCTAssertFalse(sut.isRefreshing(feed))
    }

    func testIsRefreshingWhenFeedUpdating() {
        sut = makeSUT()
        let feed = RSSFeed(
            id: FeedID("1"),
            title: "Test",
            url: nil,
            isUpdating: true,
            lastUpdate: nil
        )
        XCTAssertTrue(sut.isRefreshing(feed))
    }

    // MARK: - Get Feed Items

    func testGetFeedItems() async throws {
        sut = makeSUT()
        let item = RSSFeedItem(
            id: FeedItemID("item-1"),
            title: "Item",
            downloadURL: URL(string: "magnet:?xt=urn:btih:abc"),
            externalURL: nil,
            size: "100",
            publishedDate: Date(),
            isNew: true
        )
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [item], total: 1))

        let result = try await sut.getFeedItems(feedID: FeedID("1"))

        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(mockFeedService.lastFeedID?.rawValue, "1")
    }

    // MARK: - Cancellation Error Handling

    func testFetchFeedsCancellationErrorIgnored() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .failure(CancellationError())

        await sut.fetchFeeds()

        // CancellationError should be silently ignored
        XCTAssertNil(sut.currentError)
        XCTAssertFalse(sut.isLoading)
    }

    func testFetchFeedsNetworkCancelledIgnored() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .failure(NetworkError.cancelled)

        await sut.fetchFeeds()

        // NetworkError.cancelled should be silently ignored
        XCTAssertNil(sut.currentError)
    }

    func testFetchFeedsNetworkNonCancelledError() async {
        sut = makeSUT()
        mockFeedService.getFeedsResult = .failure(NetworkError.timeout)

        await sut.fetchFeeds()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isLoading)
    }
}
