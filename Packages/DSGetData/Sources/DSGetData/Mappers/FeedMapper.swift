import Foundation
import DSGetDomain

/// Maps between RSS Feed DTOs and Domain Entities.
public struct FeedMapper {

    public init() {}

    // MARK: - DTO to Entity

    /// Maps an RSSFeedDTO to an RSSFeed entity.
    public func mapToEntity(_ dto: RSSFeedDTO) -> RSSFeed {
        RSSFeed(
            id: FeedID(dto.id.stringValue),
            title: dto.title,
            url: dto.url.flatMap { URL(string: $0) },
            isUpdating: dto.isUpdating ?? false,
            lastUpdate: dto.lastUpdate.map { Date(timeIntervalSince1970: $0) }
        )
    }

    /// Maps a list of RSSFeedDTOs to entities.
    public func mapToEntities(_ dtos: [RSSFeedDTO]) -> [RSSFeed] {
        dtos.map { mapToEntity($0) }
    }

    /// Maps an RSSFeedItemDTO to an RSSFeedItem entity.
    public func mapItemToEntity(_ dto: RSSFeedItemDTO) -> RSSFeedItem {
        RSSFeedItem(
            id: FeedItemID(dto.id ?? UUID().uuidString),
            title: dto.title ?? "",
            downloadURL: resolveDownloadURL(dto),
            externalURL: dto.externalLink.flatMap { URL(string: $0) },
            size: dto.size,
            publishedDate: dto.time.map { Date(timeIntervalSince1970: $0) },
            isNew: dto.isNew ?? false
        )
    }

    /// Maps a list of RSSFeedItemDTOs to entities.
    public func mapItemsToEntities(_ dtos: [RSSFeedItemDTO]) -> [RSSFeedItem] {
        dtos.map { mapItemToEntity($0) }
    }

    // MARK: - Private Methods

    private func resolveDownloadURL(_ dto: RSSFeedItemDTO) -> URL? {
        // Priority: downloadUri > link > enclosure.url > externalLink
        let urlString = dto.downloadUri ?? dto.link ?? dto.enclosure?.url ?? dto.externalLink
        return urlString.flatMap { URL(string: $0) }
    }
}
