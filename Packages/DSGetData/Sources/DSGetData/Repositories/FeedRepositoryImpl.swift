import Foundation
import DSGetDomain

/// Implementation of RSSRepositoryProtocol with cache-first strategy.
public final class FeedRepositoryImpl: RSSRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: FeedRemoteDataSource
    private let cacheRepository: CacheRepositoryProtocol
    private let mapper: FeedMapper

    public init(
        remoteDataSource: FeedRemoteDataSource,
        cacheRepository: CacheRepositoryProtocol,
        mapper: FeedMapper = FeedMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.cacheRepository = cacheRepository
        self.mapper = mapper
    }

    public func getFeeds(forceRefresh: Bool) async throws -> [RSSFeed] {
        // Return cached if available and not forcing refresh
        if !forceRefresh, let cached = await cacheRepository.getCachedFeeds() {
            return cached
        }

        // Fetch from remote
        let dto = try await remoteDataSource.fetchFeeds(offset: nil, limit: nil)
        let feeds = mapper.mapToEntities(dto.sites)

        // Update cache
        await cacheRepository.setCachedFeeds(feeds)

        return feeds
    }

    public func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem> {
        let dto = try await remoteDataSource.fetchFeedItems(
            feedID: feedID.rawValue,
            offset: pagination?.offset,
            limit: pagination?.limit
        )

        let items = mapper.mapItemsToEntities(dto.items)

        return PaginatedResult(
            items: items,
            total: dto.total ?? items.count,
            offset: dto.offset ?? pagination?.offset ?? 0
        )
    }

    public func refreshFeed(id: FeedID) async throws {
        try await remoteDataSource.refreshFeed(id: id.rawValue)
        await cacheRepository.invalidate(.feeds)
    }
}
