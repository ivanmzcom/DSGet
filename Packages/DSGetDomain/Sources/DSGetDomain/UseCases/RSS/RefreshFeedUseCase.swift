import Foundation

/// Protocol for refreshing a feed use case.
public protocol RefreshFeedUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter feedID: The feed to refresh.
    func execute(feedID: FeedID) async throws
}

/// Use case for refreshing an RSS feed.
public final class RefreshFeedUseCase: RefreshFeedUseCaseProtocol, @unchecked Sendable {
    private let rssRepository: RSSRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol

    public init(
        rssRepository: RSSRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol
    ) {
        self.rssRepository = rssRepository
        self.cacheRepository = cacheRepository
    }

    public func execute(feedID: FeedID) async throws {
        try await rssRepository.refreshFeed(id: feedID)
        await cacheRepository.invalidate(.feeds)
    }
}
