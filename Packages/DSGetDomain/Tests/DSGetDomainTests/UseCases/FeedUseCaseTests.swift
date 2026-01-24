import XCTest
@testable import DSGetDomain

// MARK: - Get Feeds Use Case Tests

final class GetFeedsUseCaseTests: XCTestCase {

    var mockRSSRepository: MockRSSRepository!
    var mockCacheRepository: MockCacheRepository!
    var mockConnectivityRepository: MockConnectivityRepository!
    var useCase: GetFeedsUseCase!

    override func setUp() async throws {
        mockRSSRepository = MockRSSRepository()
        mockCacheRepository = MockCacheRepository()
        mockConnectivityRepository = MockConnectivityRepository()

        useCase = GetFeedsUseCase(
            rssRepository: mockRSSRepository,
            cacheRepository: mockCacheRepository,
            connectivityRepository: mockConnectivityRepository
        )
    }

    func testExecuteOnlineReturnsFeeds() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        mockRSSRepository.feeds = [createTestFeed(id: "1"), createTestFeed(id: "2")]

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.feeds.count, 2)
        XCTAssertFalse(result.isFromCache)
        XCTAssertEqual(mockRSSRepository.getFeedsCallCount, 1)
    }

    func testExecuteForceRefresh() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        await mockCacheRepository.setCachedFeeds([createTestFeed(id: "cached")])
        mockRSSRepository.feeds = [createTestFeed(id: "fresh")]

        // When
        let result = try await useCase.execute(forceRefresh: true)

        // Then
        XCTAssertEqual(result.feeds.count, 1)
        XCTAssertEqual(result.feeds.first?.id.rawValue, "fresh")
        XCTAssertFalse(result.isFromCache)
    }

    func testExecuteOfflineReturnsCachedFeeds() async throws {
        // Given
        mockConnectivityRepository._isConnected = false
        await mockCacheRepository.setCachedFeeds([createTestFeed(id: "cached")])

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.feeds.count, 1)
        XCTAssertTrue(result.isFromCache)
        XCTAssertEqual(mockRSSRepository.getFeedsCallCount, 0)
    }

    func testExecuteOfflineWithNoCacheThrowsError() async throws {
        // Given
        mockConnectivityRepository._isConnected = false
        // No cached feeds

        // When/Then
        do {
            _ = try await useCase.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DomainError)
        }
    }

    func testExecuteNetworkErrorFallsBackToCache() async throws {
        // Given
        mockConnectivityRepository._isConnected = true
        mockRSSRepository.errorToThrow = DomainError.noConnection
        await mockCacheRepository.setCachedFeeds([createTestFeed(id: "cached")])

        // When
        let result = try await useCase.execute()

        // Then
        XCTAssertEqual(result.feeds.count, 1)
        XCTAssertTrue(result.isFromCache)
    }

    private func createTestFeed(id: String) -> RSSFeed {
        RSSFeed(
            id: FeedID(id),
            title: "Feed \(id)",
            url: URL(string: "https://example.com/feed/\(id)"),
            isUpdating: false,
            lastUpdate: Date()
        )
    }
}

// MARK: - Get Feed Items Use Case Tests

final class GetFeedItemsUseCaseTests: XCTestCase {

    var mockRSSRepository: MockRSSRepository!
    var useCase: GetFeedItemsUseCase!

    override func setUp() async throws {
        mockRSSRepository = MockRSSRepository()
        useCase = GetFeedItemsUseCase(rssRepository: mockRSSRepository)
    }

    func testExecuteReturnsItems() async throws {
        // Given
        let feedID = FeedID("feed-1")
        mockRSSRepository.feedItems = [
            createTestFeedItem(id: "1"),
            createTestFeedItem(id: "2")
        ]

        // When
        let result = try await useCase.execute(feedID: feedID, pagination: nil)

        // Then
        XCTAssertEqual(result.items.count, 2)
        XCTAssertEqual(mockRSSRepository.getFeedItemsCallCount, 1)
    }

    func testExecuteWithPagination() async throws {
        // Given
        let feedID = FeedID("feed-1")
        let pagination = PaginationRequest(offset: 10, limit: 20)
        mockRSSRepository.feedItems = [createTestFeedItem(id: "1")]

        // When
        let result = try await useCase.execute(feedID: feedID, pagination: pagination)

        // Then
        XCTAssertEqual(result.items.count, 1)
        XCTAssertEqual(mockRSSRepository.getFeedItemsCallCount, 1)
    }

    func testExecuteRepositoryError() async throws {
        // Given
        let feedID = FeedID("feed-1")
        mockRSSRepository.errorToThrow = DomainError.feedNotFound(feedID)

        // When/Then
        do {
            _ = try await useCase.execute(feedID: feedID, pagination: nil)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
            XCTAssertTrue(error is DomainError)
        }
    }

    private func createTestFeedItem(id: String) -> RSSFeedItem {
        RSSFeedItem(
            id: FeedItemID(id),
            title: "Item \(id)",
            downloadURL: URL(string: "magnet:?xt=urn:btih:\(id)"),
            externalURL: URL(string: "https://example.com/item/\(id)"),
            size: "104857600",
            publishedDate: Date(),
            isNew: false
        )
    }
}

// MARK: - Refresh Feed Use Case Tests

final class RefreshFeedUseCaseTests: XCTestCase {

    var mockRSSRepository: MockRSSRepository!
    var mockCacheRepository: MockCacheRepository!
    var useCase: RefreshFeedUseCase!

    override func setUp() async throws {
        mockRSSRepository = MockRSSRepository()
        mockCacheRepository = MockCacheRepository()
        useCase = RefreshFeedUseCase(
            rssRepository: mockRSSRepository,
            cacheRepository: mockCacheRepository
        )
    }

    func testExecuteRefreshesFeed() async throws {
        // Given
        let feedID = FeedID("feed-1")

        // When
        try await useCase.execute(feedID: feedID)

        // Then
        XCTAssertEqual(mockRSSRepository.refreshFeedCallCount, 1)
    }

    func testExecuteInvalidatesCache() async throws {
        // Given
        let feedID = FeedID("feed-1")
        await mockCacheRepository.setCachedFeeds([createTestFeed(id: "1")])

        // When
        try await useCase.execute(feedID: feedID)

        // Then
        let invalidateCount = await mockCacheRepository.invalidateCallCount
        XCTAssertEqual(invalidateCount, 1)
    }

    func testExecuteRepositoryError() async throws {
        // Given
        let feedID = FeedID("feed-1")
        mockRSSRepository.errorToThrow = DomainError.feedNotFound(feedID)

        // When/Then
        do {
            try await useCase.execute(feedID: feedID)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is DomainError)
        }
    }

    private func createTestFeed(id: String) -> RSSFeed {
        RSSFeed(
            id: FeedID(id),
            title: "Feed \(id)",
            url: URL(string: "https://example.com/feed/\(id)"),
            isUpdating: false,
            lastUpdate: Date()
        )
    }
}
