//
//  FeedDetailView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 28/9/25.
//


import SwiftUI
import DSGetCore

struct FeedDetailView: View {
    var onClose: (() -> Void)? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
        .listStyle(.insetGrouped)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(viewModel.feed.title)
        .toolbar {
            if let onClose = onClose, horizontalSizeClass != .compact {
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
        .sheet(item: $viewModel.presentedAddTaskLink, onDismiss: { viewModel.presentedAddTaskLink = nil }) { link in
            NavigationStack {
                AddTaskView(prefilledURL: link.url, feedItemTitle: link.title)
            }
        }
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
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

                if let detail = detailText {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 6)
    }

    private var detailText: String? {
        guard let date = item.publishedDate else { return nil }
        return feedRelativeDateFormatter.localizedString(for: date, relativeTo: Date())
    }
}
