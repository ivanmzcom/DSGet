import Foundation

/// Protocol for fetching RSS feeds use case.
public protocol GetFeedsUseCaseProtocol: Sendable {
    /// Executes the use case.
    /// - Parameter forceRefresh: If true, bypasses cache.
    /// - Returns: Result containing feeds and cache status.
    func execute(forceRefresh: Bool) async throws -> GetFeedsResult
}

/// Use case for fetching RSS feeds with offline support.
public final class GetFeedsUseCase: GetFeedsUseCaseProtocol, @unchecked Sendable {
    private let rssRepository: RSSRepositoryProtocol
    private let cacheRepository: CacheRepositoryProtocol
    private let connectivityRepository: ConnectivityRepositoryProtocol

    public init(
        rssRepository: RSSRepositoryProtocol,
        cacheRepository: CacheRepositoryProtocol,
        connectivityRepository: ConnectivityRepositoryProtocol
    ) {
        self.rssRepository = rssRepository
        self.cacheRepository = cacheRepository
        self.connectivityRepository = connectivityRepository
    }

    public func execute(forceRefresh: Bool = false) async throws -> GetFeedsResult {
        // If not forcing refresh, try cache first
        if !forceRefresh, let cached = await cacheRepository.getCachedFeeds() {
            return GetFeedsResult(feeds: cached, isFromCache: true)
        }

        // Check connectivity
        let isConnected = await connectivityRepository.isConnected
        guard isConnected else {
            if let cached = await cacheRepository.getCachedFeeds() {
                return GetFeedsResult(feeds: cached, isFromCache: true)
            }
            throw DomainError.noConnection
        }

        // Fetch fresh data
        let feeds = try await rssRepository.getFeeds(forceRefresh: forceRefresh)

        // Update cache
        await cacheRepository.setCachedFeeds(feeds)

        return GetFeedsResult(feeds: feeds, isFromCache: false)
    }
}
