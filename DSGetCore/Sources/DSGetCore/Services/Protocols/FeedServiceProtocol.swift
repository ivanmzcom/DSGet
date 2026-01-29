import Foundation

/// Result of fetching feeds.
public struct FeedsResult: Sendable {
    public let feeds: [RSSFeed]
    public let isFromCache: Bool

    public init(feeds: [RSSFeed], isFromCache: Bool) {
        self.feeds = feeds
        self.isFromCache = isFromCache
    }
}

/// Protocol for RSS feed operations.
public protocol FeedServiceProtocol: Sendable {
    /// Fetches all RSS feeds with caching and offline support.
    /// - Parameter forceRefresh: If true, bypasses cache.
    /// - Returns: Result containing feeds and cache status.
    func getFeeds(forceRefresh: Bool) async throws -> FeedsResult

    /// Fetches items for a specific feed.
    /// - Parameters:
    ///   - feedID: The feed to get items for.
    ///   - pagination: Optional pagination parameters.
    /// - Returns: Paginated result of feed items.
    func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem>

    /// Triggers a refresh of a specific feed.
    /// - Parameter id: The feed ID to refresh.
    func refreshFeed(id: FeedID) async throws
}
