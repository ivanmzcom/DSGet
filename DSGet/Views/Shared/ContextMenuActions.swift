//
//  ContextMenuActions.swift
//  DSGet
//
//  Reusable context menu components for tasks, feeds, and search results.
//

import SwiftUI
import UIKit
import DSGetCore

// MARK: - Clipboard Utilities

enum ClipboardUtility {

    static func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}

// MARK: - Task Context Menu

struct TaskContextMenu: View {
    let task: DownloadTask
    let onPause: () -> Void
    let onResume: () -> Void
    let onDelete: () -> Void

    private var isPaused: Bool {
        task.isPaused
    }

    private var canTogglePause: Bool {
        !(task.type == .emule && task.isCompleted)
    }

    var body: some View {
        Group {
            // Pause/Resume
            Button {
                isPaused ? onResume() : onPause()
            } label: {
                Label(
                    isPaused ? "Resume" : "Pause",
                    systemImage: isPaused ? "play.fill" : "pause.fill"
                )
            }
            .disabled(!canTogglePause)

            // Delete
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(String.localized("taskItem.action.delete"), systemImage: "trash")
            }

            Divider()

            // Copy URL
            if let uri = task.detail?.uri, !uri.isEmpty {
                Button {
                    ClipboardUtility.copy(uri)
                } label: {
                    Label(String.localized("taskItem.action.copyURL"), systemImage: "doc.on.doc")
                }
            }
        }
    }
}

// MARK: - Feed Context Menu

struct FeedContextMenu: View {
    let feed: RSSFeed
    let isFavorite: Bool
    let onRefresh: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Group {
            // Refresh
            Button {
                onRefresh()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            // Toggle Favorite
            Button {
                onToggleFavorite()
            } label: {
                Label(
                    isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: isFavorite ? "star.slash" : "star"
                )
            }

            Divider()

            // Copy URL
            if let feedURL = feed.url {
                Button {
                    ClipboardUtility.copy(feedURL.absoluteString)
                } label: {
                    Label("Copy Feed URL", systemImage: "doc.on.doc")
                }
            }

            Divider()

            // Delete
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Feed", systemImage: "trash")
            }
        }
    }
}

// MARK: - Feed Item Context Menu

struct FeedItemContextMenu: View {
    let item: RSSFeedItem
    let onDownload: () -> Void

    var body: some View {
        Group {
            // Download
            Button {
                onDownload()
            } label: {
                Label(String.localized("feed.action.download"), systemImage: "arrow.down.circle")
            }

            Divider()

            // Copy Title
            Button {
                ClipboardUtility.copy(item.title)
            } label: {
                Label(String.localized("feed.action.copyTitle"), systemImage: "doc.on.doc")
            }

            // Copy Download URL
            if let downloadURL = item.downloadURL {
                Button {
                    ClipboardUtility.copy(downloadURL.absoluteString)
                } label: {
                    Label(String.localized("feed.action.copyDownloadURL"), systemImage: "link")
                }
            }
        }
    }
}

// MARK: - View Extension for Context Menus

extension View {

    /// Applies a task context menu to the view.
    func taskContextMenu(
        task: DownloadTask,
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.contextMenu {
            TaskContextMenu(
                task: task,
                onPause: onPause,
                onResume: onResume,
                onDelete: onDelete
            )
        }
    }

    /// Applies a feed context menu to the view.
    func feedContextMenu(
        feed: RSSFeed,
        isFavorite: Bool,
        onRefresh: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        self.contextMenu {
            FeedContextMenu(
                feed: feed,
                isFavorite: isFavorite,
                onRefresh: onRefresh,
                onToggleFavorite: onToggleFavorite,
                onDelete: onDelete
            )
        }
    }

    /// Applies a feed item context menu to the view.
    func feedItemContextMenu(
        item: RSSFeedItem,
        onDownload: @escaping () -> Void
    ) -> some View {
        self.contextMenu {
            FeedItemContextMenu(
                item: item,
                onDownload: onDownload
            )
        }
    }
}
