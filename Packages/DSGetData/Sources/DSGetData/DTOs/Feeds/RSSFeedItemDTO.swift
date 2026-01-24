import Foundation

/// RSS feed items list response.
public struct RSSFeedItemsListDTO: Decodable {
    public let items: [RSSFeedItemDTO]
    public let total: Int?
    public let offset: Int?

    private enum CodingKeys: String, CodingKey {
        case feeds, items, total, offset
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decodeIfPresent(Int.self, forKey: .total)
        offset = try container.decodeIfPresent(Int.self, forKey: .offset)

        if let directItems = try container.decodeIfPresent([RSSFeedItemDTO].self, forKey: .items),
           !directItems.isEmpty {
            items = directItems
        } else if let feedItems = try container.decodeIfPresent([RSSFeedItemDTO].self, forKey: .feeds) {
            items = feedItems
        } else {
            items = []
        }
    }

    public init(items: [RSSFeedItemDTO], total: Int? = nil, offset: Int? = nil) {
        self.items = items
        self.total = total
        self.offset = offset
    }
}

/// Individual RSS feed item.
public struct RSSFeedItemDTO: Decodable {
    public let id: String?
    public let title: String?
    public let link: String?
    public let externalLink: String?
    public let downloadUri: String?
    public let size: String?
    public let time: TimeInterval?
    public let isNew: Bool?
    public let enclosure: RSSFeedItemEnclosureDTO?

    private enum CodingKeys: String, CodingKey {
        case id, title, link, externalLink, downloadUri, size, time, isNew, enclosure
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        externalLink = try container.decodeIfPresent(String.self, forKey: .externalLink)
        downloadUri = try container.decodeIfPresent(String.self, forKey: .downloadUri)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        isNew = try container.decodeIfPresent(Bool.self, forKey: .isNew)
        enclosure = try container.decodeIfPresent(RSSFeedItemEnclosureDTO.self, forKey: .enclosure)

        // Handle time as number or string
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .time) {
            time = timeInterval
        } else if let stringValue = try? container.decode(String.self, forKey: .time),
                  let doubleValue = Double(stringValue) {
            time = doubleValue
        } else {
            time = nil
        }
    }

    public init(
        id: String? = nil,
        title: String? = nil,
        link: String? = nil,
        externalLink: String? = nil,
        downloadUri: String? = nil,
        size: String? = nil,
        time: TimeInterval? = nil,
        isNew: Bool? = nil,
        enclosure: RSSFeedItemEnclosureDTO? = nil
    ) {
        self.id = id
        self.title = title
        self.link = link
        self.externalLink = externalLink
        self.downloadUri = downloadUri
        self.size = size
        self.time = time
        self.isNew = isNew
        self.enclosure = enclosure
    }
}

/// RSS item enclosure for media.
public struct RSSFeedItemEnclosureDTO: Decodable {
    public let url: String?

    public init(url: String?) {
        self.url = url
    }
}
