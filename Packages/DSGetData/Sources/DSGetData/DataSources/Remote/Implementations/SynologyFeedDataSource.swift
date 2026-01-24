import Foundation

/// Synology API implementation for RSS feed operations.
public final class SynologyFeedDataSource: FeedRemoteDataSource, @unchecked Sendable {

    private let apiClient: SynologyAPIClient

    public init(apiClient: SynologyAPIClient) {
        self.apiClient = apiClient
    }

    public func fetchFeeds(offset: Int?, limit: Int?) async throws -> RSSSiteListDTO {
        var params: [String: String] = [:]

        if let offset = offset {
            params["offset"] = String(offset)
        }
        if let limit = limit {
            params["limit"] = String(limit)
        }

        let response: SynoResponseDTO<RSSSiteListDTO> = try await apiClient.get(
            endpoint: .rssSite,
            api: "SYNO.DownloadStation.RSS.Site",
            method: "list",
            version: 1,
            params: params
        )

        guard let data = response.data else {
            return RSSSiteListDTO(sites: [])
        }

        return data
    }

    public func fetchFeedItems(feedID: String, offset: Int?, limit: Int?) async throws -> RSSFeedItemsListDTO {
        var params: [String: String] = ["id": feedID]

        if let offset = offset {
            params["offset"] = String(offset)
        }
        if let limit = limit {
            params["limit"] = String(limit)
        }

        let response: SynoResponseDTO<RSSFeedItemsListDTO> = try await apiClient.get(
            endpoint: .rssFeed,
            api: "SYNO.DownloadStation.RSS.Feed",
            method: "list",
            version: 1,
            params: params
        )

        guard let data = response.data else {
            return RSSFeedItemsListDTO(items: [])
        }

        return data
    }

    public func refreshFeed(id: String) async throws {
        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .rssSite,
            api: "SYNO.DownloadStation.RSS.Site",
            method: "refresh",
            version: 1,
            params: ["id": id]
        )
    }
}
