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

    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    @State private var viewModel: FeedDetailViewModel

    init(feed: RSSFeed, onClose: (() -> Void)? = nil) {
        _viewModel = State(initialValue: FeedDetailViewModel(feed: feed))
        self.onClose = onClose
    }

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.handleItemSelection(item)
                } label: {
                    FeedItemRow(item: item)
                }
                .buttonStyle(.plain)
                .task { await viewModel.loadMoreIfNeeded(currentItem: item) }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowBackground(Color.clear)
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
        .dsgetContentBackground()
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
            DSGetLoadingContentStateView(
                title: String.localized("feedItems.state.loading.title"),
                description: String.localized("feedItems.state.loading.description")
            )
        case .error(let error):
            DSGetContentStateView.error(error, onRetry: retryFeedItems)
        case .empty:
            DSGetContentStateView(
                title: String.localized("feed.detail.noItems"),
                description: String.localized("feed.detail.noItems.description"),
                systemImage: "doc.plaintext",
                primaryActionTitle: String.localized("feed.action.refresh"),
                primaryAction: retryFeedItems
            )
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
            DSGetIconBadge(
                systemName: item.canDownload ? "arrow.down.circle.fill" : "doc.text",
                tint: item.canDownload ? .accentColor : .secondary,
                size: 32
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(item.canDownload ? .primary : .secondary)

                    if item.isNew {
                        Text(String.localized("feed.item.new"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
        .padding(DSGetDesign.rowPadding)
        .dsgetSurface(.row)
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
