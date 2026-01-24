import Foundation

/// Protocol for RSS feed data access.
public protocol RSSRepositoryProtocol: Sendable {

    /// Fetches all RSS feeds.
    /// - Parameter forceRefresh: If true, bypasses cache and fetches from server.
    /// - Returns: Array of RSS feeds.
    func getFeeds(forceRefresh: Bool) async throws -> [RSSFeed]

    /// Fetches items for a specific feed.
    /// - Parameters:
    ///   - feedID: The feed to get items for.
    ///   - pagination: Optional pagination parameters.
    /// - Returns: Paginated result of feed items.
    func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem>

    /// Triggers a refresh of a feed.
    /// - Parameter id: The feed ID to refresh.
    func refreshFeed(id: FeedID) async throws
}

/// Result of fetching feeds.
public struct GetFeedsResult: Sendable {
    public let feeds: [RSSFeed]
    public let isFromCache: Bool

    public init(feeds: [RSSFeed], isFromCache: Bool) {
        self.feeds = feeds
        self.isFromCache = isFromCache
    }
}
