//
//  FeedsViewModel.swift
//  DSGet
//
//  Centralized ViewModel for RSS feed management.
//

import Foundation
import SwiftUI
import DSGetCore

// MARK: - FeedsViewModel

/// ViewModel that centralizes state and logic for RSS feeds.
@MainActor
@Observable
final class FeedsViewModel: DomainErrorHandling, OfflineModeSupporting {
    // MARK: - Published State

    /// Complete list of feeds.
    private(set) var feeds: [RSSFeed] = []

    /// Selected feed ID.
    var selectedFeedID: FeedID?

    /// Indicates if data is loading.
    private(set) var isLoading: Bool = false

    /// Indicates if in offline mode.
    var isOfflineMode: Bool = false

    /// IDs of feeds being refreshed.
    private(set) var refreshingFeeds: Set<FeedID> = []

    /// Current error.
    var currentError: DSGetError?

    /// Indicates if error should be shown.
    var showingError: Bool = false

    // MARK: - Filter State

    /// Search text.
    var searchText: String = ""

    // MARK: - Favorites

    /// Favorite feed IDs (in-memory only).
    private(set) var favoriteFeedIDs: Set<String> = []

    // MARK: - Computed Properties

    /// Visible feeds after applying filters.
    var visibleFeeds: [RSSFeed] {
        guard !searchText.isEmpty else { return feeds }
        return feeds.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    /// Favorite feeds.
    var favoriteFeeds: [RSSFeed] {
        feeds.filter { favoriteFeedIDs.contains($0.id.rawValue) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    /// Current selected feed.
    var selectedFeed: RSSFeed? {
        guard let id = selectedFeedID else { return nil }
        return feeds.first { $0.id == id }
    }

    // MARK: - Injected Dependencies

    private let feedService: FeedServiceProtocol

    // MARK: - Initialization

    init(feedService: FeedServiceProtocol? = nil) {
        self.feedService = feedService ?? DIService.feedService
    }

    // MARK: - Public Methods

    /// Fetches feeds from server or cache.
    func fetchFeeds(forceRefresh: Bool = false) async {
        isLoading = true
        currentError = nil
        showingError = false

        do {
            let result = try await feedService.getFeeds(forceRefresh: forceRefresh)

            feeds = result.feeds.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
            isOfflineMode = result.isFromCache
        } catch is CancellationError {
            // Ignore - SwiftUI task was cancelled (view disappeared)
        } catch let netError as NetworkError {
            // Check if it's a cancellation
            if case .cancelled = netError {
                // Ignore - network request was cancelled due to view lifecycle
            } else {
                handleError(netError)
            }
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Fetches feeds only if no data exists (to avoid SwiftUI cancellations).
    func fetchFeedsIfNeeded() async {
        // If feeds are already loaded, do nothing
        guard feeds.isEmpty else { return }
        // If already loading, don't duplicate the request
        guard !isLoading else { return }

        await fetchFeeds(forceRefresh: false)
    }

    /// Refreshes feeds invalidating the cache.
    func refresh() async {
        await fetchFeeds(forceRefresh: true)
    }

    /// Refreshes a specific feed.
    func refreshFeed(_ feed: RSSFeed) async {
        guard !refreshingFeeds.contains(feed.id) else { return }

        refreshingFeeds.insert(feed.id)
        defer { refreshingFeeds.remove(feed.id) }

        do {
            try await feedService.refreshFeed(id: feed.id)
            await fetchFeeds(forceRefresh: true)
        } catch {
            handleError(error)
        }
    }

    /// Gets items from a feed.
    func getFeedItems(feedID: FeedID, offset: Int = 0, limit: Int = 50) async throws -> PaginatedResult<RSSFeedItem> {
        let pagination = PaginationRequest(offset: offset, limit: limit)
        return try await feedService.getFeedItems(feedID: feedID, pagination: pagination)
    }

    /// Toggles favorite state for a feed.
    func toggleFavorite(_ feed: RSSFeed) {
        var updatedFavorites = favoriteFeedIDs
        if updatedFavorites.contains(feed.id.rawValue) {
            updatedFavorites.remove(feed.id.rawValue)
        } else {
            updatedFavorites.insert(feed.id.rawValue)
        }
        favoriteFeedIDs = updatedFavorites
    }

    /// Checks if a feed is in favorites.
    func isFavorite(_ feed: RSSFeed) -> Bool {
        favoriteFeedIDs.contains(feed.id.rawValue)
    }

    /// Checks if a feed is being refreshed.
    func isRefreshing(_ feed: RSSFeed) -> Bool {
        refreshingFeeds.contains(feed.id) || feed.isUpdating
    }
}
