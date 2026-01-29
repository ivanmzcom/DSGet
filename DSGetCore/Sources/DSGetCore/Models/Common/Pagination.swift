import Foundation

/// Pagination parameters for list requests.
public struct PaginationRequest: Equatable, Sendable, Hashable {
    public let offset: Int
    public let limit: Int

    public init(offset: Int = 0, limit: Int = 50) {
        self.offset = max(0, offset)
        self.limit = max(1, limit)
    }

    public static let `default` = Self()

    /// Creates request for the next page.
    public func next() -> Self {
        Self(offset: offset + limit, limit: limit)
    }

    /// Creates request for the previous page.
    public func previous() -> Self {
        Self(offset: max(0, offset - limit), limit: limit)
    }
}

/// Paginated result wrapper.
public struct PaginatedResult<T: Sendable>: Sendable {
    public let items: [T]
    public let total: Int
    public let offset: Int
    public let limit: Int

    public init(items: [T], total: Int, offset: Int = 0, limit: Int = 50) {
        self.items = items
        self.total = total
        self.offset = offset
        self.limit = max(1, limit)
    }

    /// Whether there are more items available.
    public var hasMore: Bool {
        offset + items.count < total
    }

    /// Current page number (0-indexed).
    public var currentPage: Int {
        offset / limit
    }

    /// Total number of pages.
    public var totalPages: Int {
        guard total > 0 else { return 0 }
        return (total + limit - 1) / limit
    }

    /// Whether this is the first page.
    public var isFirstPage: Bool {
        offset == 0
    }

    /// Whether this is the last page.
    public var isLastPage: Bool {
        !hasMore
    }
}
