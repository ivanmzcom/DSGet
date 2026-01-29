//
//  FeedDetailViewModel.swift
//  DSGet
//
//  ViewModel for the feed detail view, handling feed items loading and refresh.
//

import Foundation
import SwiftUI
import DSGetCore

// MARK: - FeedDetailViewModel

/// ViewModel that manages the state and logic for feed detail view.
@MainActor
@Observable
final class FeedDetailViewModel: DomainErrorHandling {
    // MARK: - Published State

    /// The feed being displayed.
    let feed: RSSFeed

    /// Items in the feed.
    private(set) var items: [RSSFeedItem] = []

    /// Whether initial content is loading.
    private(set) var isLoading: Bool = false

    /// Whether more items are loading.
    private(set) var isLoadingMore: Bool = false

    /// Whether there are more items to load.
    private(set) var hasMoreItems: Bool = true

    /// Whether the feed is being refreshed.
    private(set) var isRefreshingFeed: Bool = false

    /// Link to present for adding a task.
    var presentedAddTaskLink: FeedLink?

    /// Current error.
    var currentError: DSGetError?

    /// Whether to show error alert.
    var showingError: Bool = false

    // MARK: - Private State

    /// Current offset for pagination.
    private var nextOffset: Int = 0

    /// Total items available.
    private var totalAvailable: Int?

    /// Set of loaded item IDs to prevent duplicates.
    private var loadedItemIDs: Set<FeedItemID> = []

    /// Page size for loading items.
    private let pageSize = 20

    // MARK: - Dependencies

    private let feedService: FeedServiceProtocol

    // MARK: - Initialization

    init(
        feed: RSSFeed,
        feedService: FeedServiceProtocol? = nil
    ) {
        self.feed = feed
        self.feedService = feedService ?? DIService.feedService
    }

    // MARK: - Public Methods

    /// Loads feed items, optionally resetting the list.
    func loadItems(reset: Bool = false) async {
        var requestOffset = 0

        if reset {
            isLoading = true
            isLoadingMore = false
            currentError = nil
            showingError = false
            nextOffset = 0
            totalAvailable = nil
            hasMoreItems = true
            loadedItemIDs = []
            requestOffset = 0
        } else {
            guard hasMoreItems, !isLoading, !isLoadingMore else { return }
            isLoadingMore = true
            requestOffset = nextOffset
        }

        do {
            let pagination = PaginationRequest(offset: requestOffset, limit: pageSize)
            let result = try await feedService.getFeedItems(feedID: feed.id, pagination: pagination)

            #if DEBUG
            print("Loaded \(result.items.count) feed items (offset: \(requestOffset))")
            #endif

            if reset {
                items = result.items
                loadedItemIDs = Set(result.items.map { $0.id })
            } else {
                let newItems = result.items.filter { !loadedItemIDs.contains($0.id) }
                if !newItems.isEmpty {
                    items.append(contentsOf: newItems)
                    loadedItemIDs.formUnion(newItems.map { $0.id })
                }
            }

            // Update pagination state
            let fetchedCount = result.items.count
            nextOffset = requestOffset + fetchedCount

            totalAvailable = result.total
            hasMoreItems = nextOffset < result.total

            if fetchedCount == 0 {
                hasMoreItems = false
            }
        } catch {
            handleError(error)
        }

        if reset {
            isLoading = false
        } else {
            isLoadingMore = false
        }
    }

    /// Refreshes the feed from the server.
    func refreshFeed() async {
        guard !isRefreshingFeed else { return }

        isRefreshingFeed = true

        do {
            try await feedService.refreshFeed(id: feed.id)
            await loadItems(reset: true)
        } catch {
            handleError(error)
        }

        isRefreshingFeed = false
    }

    /// Loads more items if the current item is near the end of the list.
    func loadMoreIfNeeded(currentItem: RSSFeedItem) async {
        guard hasMoreItems, !isLoadingMore, !isLoading else { return }
        guard currentItem.id == items.last?.id else { return }

        await loadItems(reset: false)
    }

    /// Handles selection of a feed item for download.
    func handleItemSelection(_ item: RSSFeedItem) {
        guard let url = item.preferredDownloadURL else {
            currentError = DSGetError.validation(.noDownloadURL)
            showingError = true
            return
        }

        presentedAddTaskLink = FeedLink(url: url.absoluteString, title: item.title)
    }

    /// Returns a shareable URL for the item.
    func shareURL(for item: RSSFeedItem) -> URL? {
        item.preferredDownloadURL
    }
}
