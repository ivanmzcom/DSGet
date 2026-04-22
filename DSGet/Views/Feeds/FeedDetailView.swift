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
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
        .task { await viewModel.loadItems(reset: true) }
        .refreshable { await viewModel.loadItems(reset: true) }
        .alert(String.localized("error.title"), isPresented: $viewModel.showingError) {
            Button(String.localized("general.ok"), role: .cancel) { }
        } message: {
            Text(viewModel.currentError?.localizedDescription ?? "An unknown error occurred.")
        }
        .overlay {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(Color.accentColor)
            } else if !viewModel.isLoading && viewModel.items.isEmpty {
                ContentUnavailableView(String.localized("feed.detail.noItems"),
                    systemImage: "doc.plaintext",
                    description: Text(String.localized("feed.detail.noItems.description"))
                )
            }
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
                .foregroundStyle(item.canDownload ? Color.accentColor : .secondary)
                .frame(width: 18)

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
                            FeedItemMetaLabel(text: "Ready", systemImage: "checkmark.circle", tint: .green)
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
        .padding(.vertical, 6)
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
