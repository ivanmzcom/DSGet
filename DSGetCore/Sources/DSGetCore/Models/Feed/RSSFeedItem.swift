import Foundation

/// Strongly typed identifier for RSS feed items.
public struct FeedItemID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible, Codable {
    public let rawValue: String

    public init(_ value: String) {
        self.rawValue = value
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// An item within an RSS feed.
public struct RSSFeedItem: Equatable, Sendable, Identifiable, Hashable {
    public let id: FeedItemID
    public let title: String
    public let downloadURL: URL?
    public let externalURL: URL?
    public let size: String?
    public let publishedDate: Date?
    public let isNew: Bool

    public init(
        id: FeedItemID,
        title: String,
        downloadURL: URL?,
        externalURL: URL?,
        size: String?,
        publishedDate: Date?,
        isNew: Bool = false
    ) {
        self.id = id
        self.title = title
        self.downloadURL = downloadURL
        self.externalURL = externalURL
        self.size = size
        self.publishedDate = publishedDate
        self.isNew = isNew
    }

    /// The preferred URL for downloading (download URL first, then external).
    public var preferredDownloadURL: URL? {
        downloadURL ?? externalURL
    }

    /// Whether this item can be downloaded.
    public var canDownload: Bool {
        preferredDownloadURL != nil
    }

    /// Time elapsed since publication.
    public var age: TimeInterval? {
        guard let published = publishedDate else { return nil }
        return Date().timeIntervalSince(published)
    }

    /// Formatted publication date.
    public var publishedDateFormatted: String? {
        guard let published = publishedDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: published, relativeTo: Date())
    }

    /// Parsed size as ByteSize if the size string is numeric.
    public var parsedSize: ByteSize? {
        guard let sizeStr = size, let bytes = Int64(sizeStr) else { return nil }
        return ByteSize(bytes: bytes)
    }
}

// MARK: - Preview

extension RSSFeedItem {
    public static func preview(
        id: String = "item-1",
        title: String = "Sample Item",
        isNew: Bool = true
    ) -> RSSFeedItem {
        RSSFeedItem(
            id: FeedItemID(id),
            title: title,
            downloadURL: URL(string: "magnet:?xt=urn:btih:example"),
            externalURL: URL(string: "https://example.com/item"),
            size: "1073741824",
            publishedDate: Date().addingTimeInterval(-3600),
            isNew: isNew
        )
    }
}
