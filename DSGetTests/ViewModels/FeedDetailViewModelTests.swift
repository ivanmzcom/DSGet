import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class FeedDetailViewModelTests: XCTestCase {

    private var mockFeedService: MockFeedService!
    private var sut: FeedDetailViewModel!

    override func setUp() {
        super.setUp()
        mockFeedService = MockFeedService()
    }

    private func makeSUT(id: String = "1", title: String = "Test Feed") -> FeedDetailViewModel {
        let feed = makeFeed(id: id, title: title)
        return FeedDetailViewModel(feed: feed, feedService: mockFeedService)
    }

    // MARK: - Helpers

    private func makeFeed(id: String = "1", title: String = "Test Feed") -> RSSFeed {
        RSSFeed(
            id: FeedID(id),
            title: title,
            url: URL(string: "https://example.com/rss"),
            isUpdating: false,
            lastUpdate: Date()
        )
    }

    private func makeFeedItem(id: String = "item-1", title: String = "Item") -> RSSFeedItem {
        RSSFeedItem(
            id: FeedItemID(id),
            title: title,
            downloadURL: URL(string: "magnet:?xt=urn:btih:abc"),
            externalURL: URL(string: "https://example.com/item"),
            size: "1073741824",
            publishedDate: Date(),
            isNew: true
        )
    }

    // MARK: - Load Items

    func testLoadItemsReset() async {
        sut = makeSUT()
        let items = [makeFeedItem(id: "1"), makeFeedItem(id: "2")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 2))

        await sut.loadItems(reset: true)

        XCTAssertEqual(sut.items.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.currentError)
    }

    func testLoadItemsAppends() async {
        sut = makeSUT()
        // First load
        let page1 = [makeFeedItem(id: "1"), makeFeedItem(id: "2")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: page1, total: 4))
        await sut.loadItems(reset: true)

        // Second load
        let page2 = [makeFeedItem(id: "3"), makeFeedItem(id: "4")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: page2, total: 4))
        await sut.loadItems(reset: false)

        XCTAssertEqual(sut.items.count, 4)
    }

    func testLoadItemsDeduplicates() async {
        sut = makeSUT()
        // First load
        let page1 = [makeFeedItem(id: "1"), makeFeedItem(id: "2")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: page1, total: 3))
        await sut.loadItems(reset: true)

        // Second load with duplicate
        let page2 = [makeFeedItem(id: "2"), makeFeedItem(id: "3")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: page2, total: 3))
        await sut.loadItems(reset: false)

        XCTAssertEqual(sut.items.count, 3)
    }

    func testLoadItemsHasMore() async {
        sut = makeSUT()
        let items = [makeFeedItem(id: "1")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 100))

        await sut.loadItems(reset: true)

        XCTAssertTrue(sut.hasMoreItems)
    }

    func testLoadItemsNoMore() async {
        sut = makeSUT()
        let items = [makeFeedItem(id: "1")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 1))

        await sut.loadItems(reset: true)

        XCTAssertFalse(sut.hasMoreItems)
    }

    func testLoadItemsEmptyStopsMore() async {
        sut = makeSUT()
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 0))

        await sut.loadItems(reset: true)

        XCTAssertFalse(sut.hasMoreItems)
    }

    func testLoadItemsError() async {
        sut = makeSUT()
        mockFeedService.getFeedItemsResult = .failure(DomainError.noConnection)

        await sut.loadItems(reset: true)

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Refresh Feed

    func testRefreshFeed() async {
        sut = makeSUT()
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 0))

        await sut.refreshFeed()

        XCTAssertTrue(mockFeedService.refreshFeedCalled)
        XCTAssertFalse(sut.isRefreshingFeed)
    }

    func testRefreshFeedError() async {
        sut = makeSUT()
        mockFeedService.refreshFeedError = DomainError.feedRefreshFailed(FeedID("1"))
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 0))

        await sut.refreshFeed()

        XCTAssertNotNil(sut.currentError)
        XCTAssertFalse(sut.isRefreshingFeed)
    }

    func testRefreshFeedPreventsDouble() async {
        sut = makeSUT()
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 0))

        await sut.refreshFeed()
        XCTAssertTrue(mockFeedService.refreshFeedCalled)
    }

    // MARK: - Load More If Needed

    func testLoadMoreIfNeededTriggersForLastItem() async {
        sut = makeSUT()
        let items = [makeFeedItem(id: "1"), makeFeedItem(id: "2")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 10))
        await sut.loadItems(reset: true)
        mockFeedService.getFeedItemsCalled = false

        let lastItem = sut.items.last!
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [makeFeedItem(id: "3")], total: 10))

        await sut.loadMoreIfNeeded(currentItem: lastItem)

        XCTAssertTrue(mockFeedService.getFeedItemsCalled)
    }

    func testLoadMoreIfNeededIgnoresNonLastItem() async {
        sut = makeSUT()
        let items = [makeFeedItem(id: "1"), makeFeedItem(id: "2")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 10))
        await sut.loadItems(reset: true)
        mockFeedService.getFeedItemsCalled = false

        await sut.loadMoreIfNeeded(currentItem: sut.items.first!)

        XCTAssertFalse(mockFeedService.getFeedItemsCalled)
    }

    // MARK: - Handle Item Selection

    func testHandleItemSelectionWithURL() {
        sut = makeSUT()
        let item = makeFeedItem()

        sut.handleItemSelection(item)

        XCTAssertNotNil(sut.presentedAddTaskLink)
        XCTAssertEqual(sut.presentedAddTaskLink?.title, "Item")
    }

    func testHandleItemSelectionNoURL() {
        sut = makeSUT()
        let item = RSSFeedItem(
            id: FeedItemID("1"),
            title: "No URL",
            downloadURL: nil,
            externalURL: nil,
            size: nil,
            publishedDate: nil,
            isNew: false
        )

        sut.handleItemSelection(item)

        XCTAssertNil(sut.presentedAddTaskLink)
        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
    }

    // MARK: - Share URL

    func testShareURL() {
        sut = makeSUT()
        let item = makeFeedItem()
        let url = sut.shareURL(for: item)

        XCTAssertNotNil(url)
    }

    func testShareURLNil() {
        sut = makeSUT()
        let item = RSSFeedItem(
            id: FeedItemID("1"),
            title: "No URL",
            downloadURL: nil,
            externalURL: nil,
            size: nil,
            publishedDate: nil,
            isNew: false
        )

        XCTAssertNil(sut.shareURL(for: item))
    }

    // MARK: - loadMoreIfNeeded Guards

    func testLoadMoreIfNeededGuardNoMoreItems() async {
        sut = makeSUT()
        let items = [makeFeedItem(id: "1")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 1))
        await sut.loadItems(reset: true)
        mockFeedService.getFeedItemsCalled = false

        // hasMoreItems is false
        await sut.loadMoreIfNeeded(currentItem: sut.items.first!)

        XCTAssertFalse(mockFeedService.getFeedItemsCalled)
    }

    // MARK: - loadItems Zero Fetch Case

    func testLoadItemsZeroFetchStopsMore() async {
        sut = makeSUT()
        // First load returns items
        let items = [makeFeedItem(id: "1")]
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: items, total: 10))
        await sut.loadItems(reset: true)

        // Second load returns zero items
        mockFeedService.getFeedItemsResult = .success(PaginatedResult(items: [], total: 10))
        await sut.loadItems(reset: false)

        XCTAssertFalse(sut.hasMoreItems)
    }

    // MARK: - shareURL Nil Path

    func testShareURLNilForItemWithNoURLs() {
        sut = makeSUT()
        let item = RSSFeedItem(
            id: FeedItemID("1"),
            title: "No URLs",
            downloadURL: nil,
            externalURL: nil,
            size: nil,
            publishedDate: nil,
            isNew: false
        )

        XCTAssertNil(sut.shareURL(for: item))
    }

    func testShareURLReturnsExternalWhenNoDownload() {
        sut = makeSUT()
        let item = RSSFeedItem(
            id: FeedItemID("1"),
            title: "External Only",
            downloadURL: nil,
            externalURL: URL(string: "https://example.com"),
            size: nil,
            publishedDate: nil,
            isNew: false
        )

        XCTAssertNotNil(sut.shareURL(for: item))
    }
}
