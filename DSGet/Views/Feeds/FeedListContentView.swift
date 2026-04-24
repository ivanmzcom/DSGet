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
    var onToggleFavorite: ((RSSFeed) -> Void)?

    // Convenience accessor
    private var feedsVM: FeedsViewModel { appViewModel.feedsViewModel }

    private func isFavorite(_ feed: RSSFeed) -> Bool {
        favoriteFeedIDs.contains(feed.id.rawValue)
    }

    @ViewBuilder
    private func feedRowView(for feed: RSSFeed) -> some View {
        let feedIsRefreshing = feedsVM.isRefreshing(feed)
        let feedIsFavorite = isFavorite(feed)

        let baseRow = FeedContentRow(feed: feed, isRefreshing: feedIsRefreshing, isFavorite: feedIsFavorite)
            .tag(feed.id)
            .feedAccessibility(feed, isFavorite: feedIsFavorite, isRefreshing: feedIsRefreshing)
            .feedRotorActions(
                onRefresh: { Task { await feedsVM.refreshFeed(feed) } },
                onToggleFavorite: { onToggleFavorite?(feed) },
                isFavorite: feedIsFavorite
            )
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
                        feedIsFavorite
                            ? String.localized("feed.action.removeFromFavorites")
                            : String.localized("feed.action.addToFavorites"),
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

        #if os(macOS)
        baseRow
        #else
        baseRow
            .hoverEffect(.highlight)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                favoriteButton(for: feed, isFavorite: feedIsFavorite)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                refreshButton(for: feed)
                shareButton(for: feed)
            }
        #endif
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
                .accessibilityIdentifier("\(AccessibilityID.FeedList.feedRow).\(feed.id.rawValue)")
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .dsgetContentBackground()
        .accessibilityIdentifier(AccessibilityID.FeedList.list)
    }

    @ViewBuilder
    private func feedList() -> some View {
        feedListContent()
            .overlay {
                feedStateOverlay
            }
            .navigationTitle(String.localized("feeds.title"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #else
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await feedsVM.refresh() }
                    } label: {
                        Label(String.localized("feed.action.refresh"), systemImage: "arrow.clockwise")
                    }
                    .disabled(feedsVM.isLoading)
                    .help(String.localized("feed.action.refresh"))
                }
            }
            #endif
            .onAppear {
                Task { await feedsVM.fetchFeedsIfNeeded() }
            }
            .refreshable { await feedsVM.refresh() }
            .errorAlert(isPresented: feedErrorAlertBinding, error: feedsVM.currentError)
            .offlineModeIndicator(isOffline: shouldShowOfflineBadge)
    }

    var body: some View {
        feedList()
    }

    private var feedContentState: FeedListContentState? {
        if feedsVM.isLoading && feedsVM.feeds.isEmpty {
            return .loading
        }

        if let currentError = feedsVM.currentError, feedsVM.feeds.isEmpty {
            return .error(currentError)
        }

        if feedsVM.isOfflineMode && feedsVM.feeds.isEmpty {
            return .offline
        }

        if feedsVM.feeds.isEmpty {
            return .empty
        }

        if feedsVM.visibleFeeds.isEmpty && !feedsVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .noResults
        }

        return nil
    }

    private var shouldShowOfflineBadge: Bool {
        feedsVM.isOfflineMode && feedContentState == nil
    }

    private var feedErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { feedsVM.showingError && !isShowingInlineError },
            set: { feedsVM.showingError = $0 }
        )
    }

    private var isShowingInlineError: Bool {
        if case .error = feedContentState {
            return true
        }
        return false
    }

    @ViewBuilder
    private var feedStateOverlay: some View {
        switch feedContentState {
        case .loading:
            DSGetLoadingContentStateView(
                title: String.localized("feeds.state.loading.title"),
                description: String.localized("feeds.state.loading.description")
            )
        case .offline:
            DSGetContentStateView.offline(onRetry: retryFeeds)
        case .error(let error):
            DSGetContentStateView.error(error, onRetry: retryFeeds)
        case .empty:
            DSGetContentStateView(
                title: String.localized("feeds.empty.noFeeds"),
                description: String.localized("feeds.empty.noFeeds.description"),
                systemImage: "dot.radiowaves.right",
                primaryActionTitle: String.localized("feed.action.refresh"),
                primaryAction: retryFeeds
            )
        case .noResults:
            DSGetContentStateView(
                title: String.localized("feeds.state.noResults.title"),
                description: String.localized(
                    "feeds.state.noResults.search",
                    feedsVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                ),
                systemImage: "magnifyingglass",
                primaryActionTitle: String.localized("state.clearSearch"),
                primaryAction: clearFeedSearch
            )
        case nil:
            EmptyView()
        }
    }

    private func retryFeeds() {
        Task { await feedsVM.fetchFeeds(forceRefresh: true) }
    }

    private func clearFeedSearch() {
        feedsVM.searchText = ""
    }

    private func shareURL(for feed: RSSFeed) -> URL? {
        feed.url
    }
}

private enum FeedListContentState {
    case loading
    case offline
    case error(DSGetError)
    case empty
    case noResults
}

// MARK: - Feed Content Row

private struct FeedContentRow: View {
    let feed: RSSFeed
    let isRefreshing: Bool
    var isFavorite: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DSGetIconBadge(
                systemName: isFavorite ? "star.fill" : "dot.radiowaves.left.and.right",
                tint: isFavorite ? .yellow : .accentColor,
                size: 32
            )

            VStack(alignment: .leading, spacing: 8) {
                Text(feed.title)
                    .font(.headline)
                    .lineLimit(2)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        if let hostText {
                            FeedMetaLabel(text: hostText, systemImage: "link")
                        }
                        if let subtitleText {
                            FeedMetaLabel(text: subtitleText, systemImage: "clock")
                        }
                        if isFavorite {
                            FeedMetaLabel(text: String.localized("feed.meta.favorite"), systemImage: "star.fill", tint: .yellow)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        if let hostText {
                            FeedMetaLabel(text: hostText, systemImage: "link")
                        }
                        if let subtitleText {
                            FeedMetaLabel(text: subtitleText, systemImage: "clock")
                        }
                        if isFavorite {
                            FeedMetaLabel(text: String.localized("feed.meta.favorite"), systemImage: "star.fill", tint: .yellow)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .padding(DSGetDesign.rowPadding)
        .dsgetSurface(.row)
    }

    private var hostText: String? {
        feed.hostname
    }

    private var subtitleText: String? {
        guard let lastUpdate = feed.lastUpdate else { return nil }
        let relative = feedRelativeDateFormatter.localizedString(for: lastUpdate, relativeTo: Date())
        return String.localized("feed.item.updated", relative)
    }
}

private struct FeedMetaLabel: View {
    let text: String
    let systemImage: String
    var tint: Color = .secondary

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(tint)
            .lineLimit(1)
    }
}
