import Foundation

/// Pure domain entity representing an RSS feed.
public struct RSSFeed: Equatable, Sendable, Identifiable, Hashable {
    public let id: FeedID
    public let title: String
    public let url: URL?
    public let isUpdating: Bool
    public let lastUpdate: Date?

    public init(
        id: FeedID,
        title: String,
        url: URL?,
        isUpdating: Bool = false,
        lastUpdate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.isUpdating = isUpdating
        self.lastUpdate = lastUpdate
    }

    /// Time elapsed since last update.
    public var timeSinceLastUpdate: TimeInterval? {
        guard let lastUpdate = lastUpdate else { return nil }
        return Date().timeIntervalSince(lastUpdate)
    }

    /// Whether the feed has been updated recently (within 1 hour).
    public var isRecentlyUpdated: Bool {
        guard let elapsed = timeSinceLastUpdate else { return false }
        return elapsed < 3600 // 1 hour
    }

    /// Hostname from the feed URL.
    public var hostname: String? {
        url?.host
    }

    /// Formatted last update string.
    public var lastUpdateFormatted: String? {
        guard let lastUpdate = lastUpdate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdate, relativeTo: Date())
    }
}

// MARK: - Preview

extension RSSFeed {
    public static func preview(
        id: String = "1",
        title: String = "Sample Feed",
        url: String = "https://example.com/rss"
    ) -> RSSFeed {
        RSSFeed(
            id: FeedID(id),
            title: title,
            url: URL(string: url),
            isUpdating: false,
            lastUpdate: Date().addingTimeInterval(-3600)
        )
    }
}
