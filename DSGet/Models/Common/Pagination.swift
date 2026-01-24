import Foundation

/// Pagination parameters for list requests.
struct PaginationRequest: Equatable, Sendable, Hashable {
    let offset: Int
    let limit: Int

    init(offset: Int = 0, limit: Int = 50) {
        self.offset = max(0, offset)
        self.limit = max(1, limit)
    }

    static let `default` = PaginationRequest()

    /// Creates request for the next page.
    func next() -> PaginationRequest {
        PaginationRequest(offset: offset + limit, limit: limit)
    }

    /// Creates request for the previous page.
    func previous() -> PaginationRequest {
        PaginationRequest(offset: max(0, offset - limit), limit: limit)
    }
}

/// Paginated result wrapper.
struct PaginatedResult<T: Sendable>: Sendable {
    let items: [T]
    let total: Int
    let offset: Int
    let limit: Int

    init(items: [T], total: Int, offset: Int = 0, limit: Int = 50) {
        self.items = items
        self.total = total
        self.offset = offset
        self.limit = max(1, limit)
    }

    /// Whether there are more items available.
    var hasMore: Bool {
        offset + items.count < total
    }

    /// Current page number (0-indexed).
    var currentPage: Int {
        offset / limit
    }

    /// Total number of pages.
    var totalPages: Int {
        guard total > 0 else { return 0 }
        return (total + limit - 1) / limit
    }

    /// Whether this is the first page.
    var isFirstPage: Bool {
        offset == 0
    }

    /// Whether this is the last page.
    var isLastPage: Bool {
        !hasMore
    }
}
