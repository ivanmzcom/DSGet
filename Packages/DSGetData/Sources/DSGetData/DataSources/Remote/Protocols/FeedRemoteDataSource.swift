import Foundation

/// Protocol for RSS feed remote data operations.
public protocol FeedRemoteDataSource: Sendable {
    func fetchFeeds(offset: Int?, limit: Int?) async throws -> RSSSiteListDTO
    func fetchFeedItems(feedID: String, offset: Int?, limit: Int?) async throws -> RSSFeedItemsListDTO
    func refreshFeed(id: String) async throws
}
