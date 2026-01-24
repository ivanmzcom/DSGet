import Foundation

/// Maps between RSS Feed DTOs and Domain Entities.
struct FeedMapper {

    init() {}

    // MARK: - DTO to Entity

    /// Maps an RSSFeedDTO to an RSSFeed entity.
    func mapToEntity(_ dto: RSSFeedDTO) -> RSSFeed {
        RSSFeed(
            id: FeedID(dto.id.stringValue),
            title: dto.title,
            url: dto.url.flatMap { URL(string: $0) },
            isUpdating: dto.isUpdating ?? false,
            lastUpdate: dto.lastUpdate.map { Date(timeIntervalSince1970: $0) }
        )
    }

    /// Maps a list of RSSFeedDTOs to entities.
    func mapToEntities(_ dtos: [RSSFeedDTO]) -> [RSSFeed] {
        dtos.map { mapToEntity($0) }
    }

    /// Maps an RSSFeedItemDTO to an RSSFeedItem entity.
    func mapItemToEntity(_ dto: RSSFeedItemDTO) -> RSSFeedItem {
        let downloadURL = resolveDownloadURL(dto)

        #if DEBUG
        print("[FeedMapper] Item: \(dto.title ?? "no title")")
        print("  - id: \(dto.id ?? "nil")")
        print("  - link: \(dto.link ?? "nil")")
        print("  - downloadUri: \(dto.downloadUri ?? "nil")")
        print("  - externalLink: \(dto.externalLink ?? "nil")")
        print("  - enclosure.url: \(dto.enclosure?.url ?? "nil")")
        print("  - resolved downloadURL: \(downloadURL?.absoluteString ?? "nil")")
        #endif

        return RSSFeedItem(
            id: FeedItemID(dto.id ?? UUID().uuidString),
            title: dto.title ?? "",
            downloadURL: downloadURL,
            externalURL: dto.externalLink.flatMap { URL(string: $0) },
            size: dto.size,
            publishedDate: dto.time.map { Date(timeIntervalSince1970: $0) },
            isNew: dto.isNew ?? false
        )
    }

    /// Maps a list of RSSFeedItemDTOs to entities.
    func mapItemsToEntities(_ dtos: [RSSFeedItemDTO]) -> [RSSFeedItem] {
        dtos.map { mapItemToEntity($0) }
    }

    // MARK: - Private Methods

    private func resolveDownloadURL(_ dto: RSSFeedItemDTO) -> URL? {
        let urlString = dto.downloadUri ?? dto.link ?? dto.enclosure?.url ?? dto.externalLink
        return urlString.flatMap { URL(string: $0) }
    }
}
