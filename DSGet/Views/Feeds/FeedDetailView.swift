//
//  FeedDetailView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 28/9/25.
//

import SwiftUI
import DSGetCore

struct FeedDetailView: View {
    var onClose: (() -> Void)?
    var onItemActivated: (() -> Void)?

    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var viewModel: FeedDetailViewModel

    init(
        feed: RSSFeed,
        onClose: (() -> Void)? = nil,
        onItemActivated: (() -> Void)? = nil
    ) {
        _viewModel = State(initialValue: FeedDetailViewModel(feed: feed))
        self.onClose = onClose
        self.onItemActivated = onItemActivated
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Button {
                    onItemActivated?()
                    viewModel.handleItemSelection(item)
                } label: {
                    FeedItemRow(item: item)
                }
                .buttonStyle(.plain)
                .task { await viewModel.loadMoreIfNeeded(currentItem: item) }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        #if os(macOS)
        .listStyle(.inset)
        #else
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .navigationTitle(viewModel.feed.title)
        .toolbar {
            if let onClose, showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String.localized("general.close")) { onClose() }
                }
            }
            ToolbarItem(placement: .principal) {
                if viewModel.isLoading && !viewModel.items.isEmpty {
                    ProgressView()
                }
            }
        }
        .task { await viewModel.loadItems(reset: true) }
        .refreshable { await viewModel.loadItems(reset: true) }
        .alert(String.localized("error.title"), isPresented: feedItemErrorAlertBinding) {
            Button(String.localized("general.ok"), role: .cancel) { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? String.localized("error.unknown"))
        }
        .overlay {
            feedItemStateOverlay
        }
        .sheet(
            item: $viewModel.presentedAddTaskLink,
            onDismiss: { viewModel.presentedAddTaskLink = nil },
            content: { link in
                NavigationStack {
                    AddTaskView(prefilledURL: link.url, feedItemTitle: link.title)
                }
            }
        )
    }

    private var showsCloseButton: Bool {
        #if os(macOS)
        true
        #else
        horizontalSizeClass != .compact
        #endif
    }

    private var feedItemContentState: FeedItemContentState? {
        if viewModel.isLoading && viewModel.items.isEmpty {
            return .loading
        }

        if let currentError = viewModel.currentError, viewModel.items.isEmpty {
            return .error(currentError)
        }

        if viewModel.items.isEmpty {
            return .empty
        }

        return nil
    }

    private var feedItemErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showingError && !isShowingInlineError },
            set: { viewModel.showingError = $0 }
        )
    }

    private var isShowingInlineError: Bool {
        if case .error = feedItemContentState {
            return true
        }
        return false
    }

    @ViewBuilder
    private var feedItemStateOverlay: some View {
        switch feedItemContentState {
        case .loading:
            ProgressView(String.localized("feedItems.state.loading.title"))
        case .error(let error):
            ContentUnavailableView {
                Label(error.requiresRelogin ? String.localized("state.permission.title") : String.localized(EmptyStateText.errorTitle),
                      systemImage: error.requiresRelogin ? "lock.shield" : "exclamationmark.triangle")
            } description: {
                Text(error.requiresRelogin ? String.localized("state.permission.description") : error.localizedDescription)
            } actions: {
                Button(String.localized(EmptyStateText.errorAction), action: retryFeedItems)
            }
        case .empty:
            ContentUnavailableView {
                Label(String.localized("feed.detail.noItems"), systemImage: "doc.plaintext")
            } description: {
                Text(String.localized("feed.detail.noItems.description"))
            } actions: {
                Button(String.localized("feed.action.refresh"), action: retryFeedItems)
            }
        case nil:
            EmptyView()
        }
    }

    private func retryFeedItems() {
        Task { await viewModel.loadItems(reset: true) }
    }
}

private enum FeedItemContentState {
    case loading
    case error(DSGetError)
    case empty
}

// MARK: - FeedLink

struct FeedLink: Identifiable {
    let id = UUID()
    let url: String
    let title: String
}

// MARK: - FeedItemRow

private let feedRelativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter
}()

struct FeedItemRow: View {
    let item: RSSFeedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.canDownload ? "arrow.down.circle" : "doc.text")
                .foregroundStyle(item.canDownload ? Color.accentColor : Color.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(item.canDownload ? .primary : .secondary)

                    if item.isNew {
                        Text(String.localized("feed.item.new"))
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        if let detailText {
                            FeedItemMetaLabel(text: detailText, systemImage: "clock")
                        }
                        if let sizeText {
                            FeedItemMetaLabel(text: sizeText, systemImage: "externaldrive")
                        }
                        if item.canDownload {
                            FeedItemMetaLabel(text: String.localized("feed.item.ready"), systemImage: "checkmark.circle", tint: .green)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        if let detailText {
                            FeedItemMetaLabel(text: detailText, systemImage: "clock")
                        }
                        if let sizeText {
                            FeedItemMetaLabel(text: sizeText, systemImage: "externaldrive")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sizeText: String? {
        item.parsedSize?.formatted ?? item.size
    }

    private var detailText: String? {
        guard let date = item.publishedDate else { return nil }
        return feedRelativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct FeedItemMetaLabel: View {
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
