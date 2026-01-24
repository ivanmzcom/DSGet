//
//  EmptyStateViews.swift
//  DSGet
//
//  Reusable empty state views with illustrations and actions.
//

import SwiftUI

// MARK: - Illustrated Empty State

struct IllustratedEmptyState: View {
    let title: String
    let description: String
    let systemImage: String
    var actionTitle: String?
    var action: (() -> Void)?
    var secondaryActionTitle: String?
    var secondaryAction: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 24) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: systemImage)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse.byLayer, options: reduceMotion ? .nonRepeating : .repeating)
            }

            // Text Content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }

            // Actions
            if actionTitle != nil || secondaryActionTitle != nil {
                VStack(spacing: 12) {
                    if let actionTitle, let action {
                        Button(action: action) {
                            Text(actionTitle)
                                .font(.headline)
                                .frame(minWidth: 160)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    if let secondaryActionTitle, let secondaryAction {
                        Button(action: secondaryAction) {
                            Text(secondaryActionTitle)
                                .font(.subheadline)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title). \(description)"))
    }
}

// MARK: - Predefined Empty States

extension IllustratedEmptyState {

    /// Empty state for no downloads.
    static func noDownloads(onAdd: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "No Downloads",
            description: "Add a torrent file or magnet link to start downloading.",
            systemImage: "arrow.down.circle.dotted",
            actionTitle: "Add Task",
            action: onAdd
        )
    }

    /// Empty state for no feeds.
    static func noFeeds(onRefresh: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "No Feeds",
            description: "Your RSS feeds will appear here. Add feeds in Download Station.",
            systemImage: "dot.radiowaves.right",
            actionTitle: "Refresh",
            action: onRefresh
        )
    }

    /// Empty state for search.
    static var searchPrompt: IllustratedEmptyState {
        IllustratedEmptyState(
            title: "Search Torrents",
            description: "Enter a search term to find torrents from enabled search modules.",
            systemImage: "magnifyingglass"
        )
    }

    /// Empty state for no search results.
    static func noSearchResults(query: String) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "No Results",
            description: "No torrents found for \"\(query)\". Try a different search term.",
            systemImage: "magnifyingglass"
        )
    }

    /// Empty state for offline mode.
    static func offline(onRetry: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "You're Offline",
            description: "Check your internet connection and try again.",
            systemImage: "wifi.slash",
            actionTitle: "Retry",
            action: onRetry
        )
    }

    /// Empty state for error.
    static func error(message: String, onRetry: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "Something Went Wrong",
            description: message,
            systemImage: "exclamationmark.triangle",
            actionTitle: "Try Again",
            action: onRetry
        )
    }

    /// Empty state for not logged in.
    static func notLoggedIn(onLogin: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "Not Connected",
            description: "Log in to your Synology NAS to manage downloads.",
            systemImage: "server.rack",
            actionTitle: "Log In",
            action: onLogin
        )
    }

    /// Empty state for feed items.
    static func noFeedItems(feedTitle: String) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: "No Items",
            description: "\"\(feedTitle)\" doesn't have any items yet.",
            systemImage: "doc.text"
        )
    }
}

// MARK: - Loading Empty State

struct LoadingEmptyState: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(.accentColor)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Loading. \(title)"))
    }
}

// MARK: - Compact Empty State

struct CompactEmptyState: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - View Modifier for Empty State

struct EmptyStateModifier<EmptyContent: View>: ViewModifier {
    let isEmpty: Bool
    let emptyContent: () -> EmptyContent

    func body(content: Content) -> some View {
        if isEmpty {
            emptyContent()
        } else {
            content
        }
    }
}

extension View {
    func emptyState<EmptyContent: View>(
        isEmpty: Bool,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) -> some View {
        modifier(EmptyStateModifier(isEmpty: isEmpty, emptyContent: emptyContent))
    }
}

// MARK: - Preview

#if DEBUG
#Preview("No Downloads") {
    IllustratedEmptyState.noDownloads(onAdd: {})
}

#Preview("No Feeds") {
    IllustratedEmptyState.noFeeds(onRefresh: {})
}

#Preview("Search Prompt") {
    IllustratedEmptyState.searchPrompt
}

#Preview("Offline") {
    IllustratedEmptyState.offline(onRetry: {})
}

#Preview("Loading") {
    LoadingEmptyState(title: "Loading Tasks...", subtitle: "Please wait")
}
#endif
