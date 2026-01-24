import Foundation

/// RSS site list response.
struct RSSSiteListDTO: Decodable {
    let sites: [RSSFeedDTO]
    let offset: Int?
    let total: Int?

    private enum CodingKeys: String, CodingKey {
        case sites, site, feeds, offset, total
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        offset = try container.decodeIfPresent(Int.self, forKey: .offset)
        total = try container.decodeIfPresent(Int.self, forKey: .total)

        if let decodedSites = try container.decodeIfPresent([RSSFeedDTO].self, forKey: .sites) {
            sites = decodedSites
        } else if let decodedSite = try container.decodeIfPresent([RSSFeedDTO].self, forKey: .site) {
            sites = decodedSite
        } else if let decodedFeeds = try container.decodeIfPresent([RSSFeedDTO].self, forKey: .feeds) {
            sites = decodedFeeds
        } else {
            sites = []
        }
    }

    init(sites: [RSSFeedDTO], offset: Int? = nil, total: Int? = nil) {
        self.sites = sites
        self.offset = offset
        self.total = total
    }
}

/// Individual RSS feed from Synology.
struct RSSFeedDTO: Decodable {
    let id: RSSFeedIDDTO
    let title: String
    let url: String?
    let isUpdating: Bool?
    let lastUpdate: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case id, title, url, isUpdating, lastUpdate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(RSSFeedIDDTO.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        isUpdating = try container.decodeIfPresent(Bool.self, forKey: .isUpdating)

        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .lastUpdate) {
            lastUpdate = timeInterval
        } else if let stringValue = try? container.decode(String.self, forKey: .lastUpdate),
                  let doubleValue = Double(stringValue) {
            lastUpdate = doubleValue
        } else {
            lastUpdate = nil
        }
    }

    init(id: RSSFeedIDDTO, title: String, url: String? = nil, isUpdating: Bool? = nil, lastUpdate: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.isUpdating = isUpdating
        self.lastUpdate = lastUpdate
    }
}

/// RSS Feed ID that can be either Int or String from API.
enum RSSFeedIDDTO: Decodable, Hashable, Sendable {
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    var stringValue: String {
        switch self {
        case .int(let value): return String(value)
        case .string(let value): return value
        }
    }
}

/// RSS feed items list response.
struct RSSFeedItemsListDTO: Decodable {
    let items: [RSSFeedItemDTO]
    let total: Int?
    let offset: Int?

    private enum CodingKeys: String, CodingKey {
        case feeds, items, total, offset
    }

    init(from decoder: Decoder) throws {
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

    init(items: [RSSFeedItemDTO], total: Int? = nil, offset: Int? = nil) {
        self.items = items
        self.total = total
        self.offset = offset
    }
}

/// Individual RSS feed item.
struct RSSFeedItemDTO: Decodable {
    let id: String?
    let title: String?
    let link: String?
    let externalLink: String?
    let downloadUri: String?
    let size: String?
    let time: TimeInterval?
    let isNew: Bool?
    let enclosure: RSSFeedItemEnclosureDTO?

    private enum CodingKeys: String, CodingKey {
        case id, title, link, size, time, isNew, enclosure
        case externalLink = "external_link"
        case downloadUri = "download_uri"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        externalLink = try container.decodeIfPresent(String.self, forKey: .externalLink)
        downloadUri = try container.decodeIfPresent(String.self, forKey: .downloadUri)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        isNew = try container.decodeIfPresent(Bool.self, forKey: .isNew)
        enclosure = try container.decodeIfPresent(RSSFeedItemEnclosureDTO.self, forKey: .enclosure)

        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .time) {
            time = timeInterval
        } else if let stringValue = try? container.decode(String.self, forKey: .time),
                  let doubleValue = Double(stringValue) {
            time = doubleValue
        } else {
            time = nil
        }
    }

    init(
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
struct RSSFeedItemEnclosureDTO: Decodable {
    let url: String?

    init(url: String?) {
        self.url = url
    }
}
