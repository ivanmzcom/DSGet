import Foundation

/// Strongly typed identifier for RSS feed items.
struct FeedItemID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible, Codable {
    let rawValue: String

    init(_ value: String) {
        self.rawValue = value
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }

    var description: String {
        rawValue
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// An item within an RSS feed.
struct RSSFeedItem: Equatable, Sendable, Identifiable, Hashable {
    let id: FeedItemID
    let title: String
    let downloadURL: URL?
    let externalURL: URL?
    let size: String?
    let publishedDate: Date?
    let isNew: Bool

    init(
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
    var preferredDownloadURL: URL? {
        downloadURL ?? externalURL
    }

    /// Whether this item can be downloaded.
    var canDownload: Bool {
        preferredDownloadURL != nil
    }

    /// Time elapsed since publication.
    var age: TimeInterval? {
        guard let published = publishedDate else { return nil }
        return Date().timeIntervalSince(published)
    }

    /// Formatted publication date.
    var publishedDateFormatted: String? {
        guard let published = publishedDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: published, relativeTo: Date())
    }

    /// Parsed size as ByteSize if the size string is numeric.
    var parsedSize: ByteSize? {
        guard let sizeStr = size, let bytes = Int64(sizeStr) else { return nil }
        return ByteSize(bytes: bytes)
    }
}

// MARK: - Preview

extension RSSFeedItem {
    static func preview(
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
