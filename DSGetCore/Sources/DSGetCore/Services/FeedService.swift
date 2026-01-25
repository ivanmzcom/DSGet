import Foundation

/// Feed service implementation for RSS operations.
public final class FeedService: FeedServiceProtocol, @unchecked Sendable {

    private let apiClient: SynologyAPIClient
    private let connectivityService: ConnectivityServiceProtocol
    private let mapper: FeedMapper

    public init(
        apiClient: SynologyAPIClient,
        connectivityService: ConnectivityServiceProtocol,
        mapper: FeedMapper = FeedMapper()
    ) {
        self.apiClient = apiClient
        self.connectivityService = connectivityService
        self.mapper = mapper
    }

    // MARK: - FeedServiceProtocol

    public func getFeeds(forceRefresh: Bool) async throws -> FeedsResult {
        // Check connectivity
        if !connectivityService.isConnected {
            throw DomainError.noConnection
        }

        // Fetch from API
        #if DEBUG
        print("[FeedService] Fetching feeds from API...")
        #endif

        let response: SynoResponseDTO<RSSSiteListDTO>
        do {
            response = try await apiClient.get(
                endpoint: .rssSite,
                api: "SYNO.DownloadStation.RSS.Site",
                method: "list",
                version: 1
            )
        } catch {
            #if DEBUG
            print("[FeedService] Error fetching feeds: \(error)")
            print("[FeedService] Error type: \(type(of: error))")
            #endif
            throw error
        }

        let dto = response.data ?? RSSSiteListDTO(sites: [])
        let feeds = mapper.mapToEntities(dto.sites)

        return FeedsResult(feeds: feeds, isFromCache: false)
    }

    public func getFeedItems(feedID: FeedID, pagination: PaginationRequest?) async throws -> PaginatedResult<RSSFeedItem> {
        var params: [String: String] = ["id": feedID.rawValue]

        if let offset = pagination?.offset {
            params["offset"] = String(offset)
        }
        if let limit = pagination?.limit {
            params["limit"] = String(limit)
        }

        let response: SynoResponseDTO<RSSFeedItemsListDTO> = try await apiClient.getWithRawResponse(
            endpoint: .rssFeed,
            api: "SYNO.DownloadStation.RSS.Feed",
            method: "list",
            version: 1,
            params: params
        )

        let dto = response.data ?? RSSFeedItemsListDTO(items: [])
        let items = mapper.mapItemsToEntities(dto.items)

        return PaginatedResult(
            items: items,
            total: dto.total ?? items.count,
            offset: dto.offset ?? pagination?.offset ?? 0
        )
    }

    public func refreshFeed(id: FeedID) async throws {
        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .rssSite,
            api: "SYNO.DownloadStation.RSS.Site",
            method: "refresh",
            version: 1,
            params: ["id": id.rawValue]
        )
    }
}
