import Foundation

/// RSS site list response.
public struct RSSSiteListDTO: Decodable {
    public let sites: [RSSFeedDTO]
    public let offset: Int?
    public let total: Int?

    private enum CodingKeys: String, CodingKey {
        case sites, site, feeds, offset, total
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        offset = try container.decodeIfPresent(Int.self, forKey: .offset)
        total = try container.decodeIfPresent(Int.self, forKey: .total)

        // Handle multiple possible key names for sites array
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

    public init(sites: [RSSFeedDTO], offset: Int? = nil, total: Int? = nil) {
        self.sites = sites
        self.offset = offset
        self.total = total
    }
}

/// Individual RSS feed from Synology.
public struct RSSFeedDTO: Decodable {
    public let id: RSSFeedIDDTO
    public let title: String
    public let url: String?
    public let isUpdating: Bool?
    public let lastUpdate: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case id, title, url, isUpdating, lastUpdate
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(RSSFeedIDDTO.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        isUpdating = try container.decodeIfPresent(Bool.self, forKey: .isUpdating)

        // Handle lastUpdate as number or string
        if let timeInterval = try? container.decode(TimeInterval.self, forKey: .lastUpdate) {
            lastUpdate = timeInterval
        } else if let stringValue = try? container.decode(String.self, forKey: .lastUpdate),
                  let doubleValue = Double(stringValue) {
            lastUpdate = doubleValue
        } else {
            lastUpdate = nil
        }
    }

    public init(id: RSSFeedIDDTO, title: String, url: String? = nil, isUpdating: Bool? = nil, lastUpdate: TimeInterval? = nil) {
        self.id = id
        self.title = title
        self.url = url
        self.isUpdating = isUpdating
        self.lastUpdate = lastUpdate
    }
}

/// RSS Feed ID that can be either Int or String from API.
public enum RSSFeedIDDTO: Decodable, Hashable, Sendable {
    case int(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            self = .string(try container.decode(String.self))
        }
    }

    public var stringValue: String {
        switch self {
        case .int(let value): return String(value)
        case .string(let value): return value
        }
    }
}
