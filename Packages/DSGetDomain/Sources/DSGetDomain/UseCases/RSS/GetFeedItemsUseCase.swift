import Foundation

/// Protocol for fetching feed items use case.
public protocol GetFeedItemsUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameters:
    ///   - feedID: The feed to get items for.
    ///   - pagination: Optional pagination parameters.
    /// - Returns: Paginated result of feed items.
    func execute(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem>
}

/// Use case for fetching items from an RSS feed.
public final class GetFeedItemsUseCase: GetFeedItemsUseCaseProtocol, @unchecked Sendable {
    private let rssRepository: RSSRepositoryProtocol

    public init(rssRepository: RSSRepositoryProtocol) {
        self.rssRepository = rssRepository
    }

    public func execute(feedID: FeedID, pagination: PaginationRequest? = nil) async throws -> PaginatedResult<RSSFeedItem> {
        try await rssRepository.getFeedItems(feedID: feedID, pagination: pagination)
    }
}
