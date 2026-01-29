//
//  FeedListContentView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

private let feedRelativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter
}()

// MARK: - Feed List Content View (Column 2 for Feeds)

struct FeedListContentView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var favoriteFeedIDs: Set<String> = []
    var onToggleFavorite: ((RSSFeed) -> Void)? = nil

    // Convenience accessor
    private var feedsVM: FeedsViewModel { appViewModel.feedsViewModel }

    private func isFavorite(_ feed: RSSFeed) -> Bool {
        favoriteFeedIDs.contains(feed.id.rawValue)
    }

    @ViewBuilder
    private func feedRowView(for feed: RSSFeed) -> some View {
        let feedIsRefreshing = feedsVM.isRefreshing(feed)
        let feedIsFavorite = isFavorite(feed)

        FeedContentRow(feed: feed, isRefreshing: feedIsRefreshing, isFavorite: feedIsFavorite)
            .tag(feed.id)
            // Accessibility
            .feedAccessibility(feed, isFavorite: feedIsFavorite, isRefreshing: feedIsRefreshing)
            .feedRotorActions(
                onRefresh: { Task { await feedsVM.refreshFeed(feed) } },
                onToggleFavorite: { onToggleFavorite?(feed) },
                isFavorite: feedIsFavorite
            )
            // Context Menu
            .contextMenu {
                Button {
                    Task { await feedsVM.refreshFeed(feed) }
                } label: {
                    Label(String.localized("feed.action.refresh"), systemImage: "arrow.clockwise")
                }

                Button {
                    onToggleFavorite?(feed)
                } label: {
                    Label(
                        feedIsFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: feedIsFavorite ? "star.slash" : "star"
                    )
                }

                if let feedURL = feed.url {
                    Divider()

                    Button {
                        ClipboardUtility.copy(feedURL.absoluteString)
                    } label: {
                        Label(String.localized("feed.action.copyFeedURL"), systemImage: "doc.on.doc")
                    }
                }
            }
            .hoverEffect(.highlight)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                favoriteButton(for: feed, isFavorite: feedIsFavorite)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                refreshButton(for: feed)
                shareButton(for: feed)
            }
    }

    @ViewBuilder
    private func favoriteButton(for feed: RSSFeed, isFavorite: Bool) -> some View {
        Button {
            onToggleFavorite?(feed)
        } label: {
            if isFavorite {
                Label(String.localized("feed.action.unfavorite"), systemImage: "star.slash")
            } else {
                Label(String.localized("feed.action.favorite"), systemImage: "star.fill")
            }
        }
        .tint(.yellow)
    }

    @ViewBuilder
    private func refreshButton(for feed: RSSFeed) -> some View {
        let feedIsRefreshing = feedsVM.isRefreshing(feed)
        Button {
            Task { await feedsVM.refreshFeed(feed) }
        } label: {
            if feedIsRefreshing {
                Label(String.localized("feed.action.refreshing"), systemImage: "hourglass")
            } else {
                Label(String.localized("feed.action.refresh"), systemImage: "arrow.clockwise")
            }
        }
        .disabled(feedIsRefreshing)
        .tint(.orange)
    }

    @ViewBuilder
    private func shareButton(for feed: RSSFeed) -> some View {
        if let url = shareURL(for: feed) {
            ShareLink(item: url) {
                Label(String.localized("feed.action.share"), systemImage: "square.and.arrow.up")
            }
            .tint(.accentColor)
        }
    }

    @ViewBuilder
    private func feedListContent() -> some View {
        @Bindable var vm = feedsVM
        List(feedsVM.visibleFeeds, selection: $vm.selectedFeedID) { feed in
            feedRowView(for: feed)
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private func feedList() -> some View {
        @Bindable var vm = feedsVM

        feedListContent()
            .navigationTitle(String.localized("feeds.title"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task { await feedsVM.fetchFeedsIfNeeded() }
            }
            .refreshable { await feedsVM.refresh() }
            .errorAlert(isPresented: $vm.showingError, error: feedsVM.currentError)
            .loadingOverlay(
                isLoading: feedsVM.isLoading,
                isEmpty: feedsVM.feeds.isEmpty,
                title: String.localized("feeds.empty.noFeeds"),
                systemImage: "dot.radiowaves.right",
                description: String.localized("feeds.empty.noFeeds.description")
            )
            .offlineModeIndicator(isOffline: feedsVM.isOfflineMode)
    }

    var body: some View {
        feedList()
    }

    private func shareURL(for feed: RSSFeed) -> URL? {
        feed.url
    }
}

// MARK: - Feed Content Row

private struct FeedContentRow: View {
    let feed: RSSFeed
    let isRefreshing: Bool
    var isFavorite: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(feed.title)
                        .font(.headline)
                        .lineLimit(2)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }

                if let subtitle = subtitleText {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding(.vertical, 6)
    }

    private var subtitleText: String? {
        guard let lastUpdate = feed.lastUpdate else { return nil }
        let relative = feedRelativeDateFormatter.localizedString(for: lastUpdate, relativeTo: Date())
        return "Updated \(relative)"
    }
}
