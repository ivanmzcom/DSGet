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
            iconView
            textContentView
            actionsView
        }
        .padding(32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(title). \(description)"))
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: systemImage)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse.byLayer, options: reduceMotion ? .nonRepeating : .repeating)
        }
    }

    @ViewBuilder
    private var textContentView: some View {
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
    }

    @ViewBuilder
    private var actionsView: some View {
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
}

// MARK: - Predefined Empty States

extension IllustratedEmptyState {
    /// Empty state for no downloads.
    static func noDownloads(onAdd: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized(EmptyStateText.noDownloadsTitle),
            description: String.localized(EmptyStateText.noDownloadsDescription),
            systemImage: "arrow.down.circle.dotted",
            actionTitle: String.localized(EmptyStateText.noDownloadsAction),
            action: onAdd
        )
    }

    /// Empty state for no feeds.
    static func noFeeds(onRefresh: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized(EmptyStateText.noFeedsTitle),
            description: String.localized(EmptyStateText.noFeedsDescription),
            systemImage: "dot.radiowaves.right",
            actionTitle: String.localized(EmptyStateText.noFeedsAction),
            action: onRefresh
        )
    }

    /// Empty state for search.
    static var searchPrompt: IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized(EmptyStateText.searchPromptTitle),
            description: String.localized(EmptyStateText.searchPromptDescription),
            systemImage: "magnifyingglass"
        )
    }

    /// Empty state for no search results.
    static func noSearchResults(query: String) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized("empty.search.noResults"),
            description: "No torrents found for \"\(query)\". Try a different search term.",
            systemImage: "magnifyingglass"
        )
    }

    /// Empty state for offline mode.
    static func offline(onRetry: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized(EmptyStateText.offlineTitle),
            description: String.localized(EmptyStateText.offlineDescription),
            systemImage: "wifi.slash",
            actionTitle: String.localized(EmptyStateText.offlineAction),
            action: onRetry
        )
    }

    /// Empty state for error.
    static func error(message: String, onRetry: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized(EmptyStateText.errorTitle),
            description: message,
            systemImage: "exclamationmark.triangle",
            actionTitle: String.localized(EmptyStateText.errorAction),
            action: onRetry
        )
    }

    /// Empty state for not logged in.
    static func notLoggedIn(onLogin: @escaping () -> Void) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized(EmptyStateText.notConnectedTitle),
            description: String.localized(EmptyStateText.notConnectedDescription),
            systemImage: "server.rack",
            actionTitle: String.localized(EmptyStateText.notConnectedAction),
            action: onLogin
        )
    }

    /// Empty state for feed items.
    static func noFeedItems(feedTitle: String) -> IllustratedEmptyState {
        IllustratedEmptyState(
            title: String.localized("feed.detail.noItems"),
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
    LoadingEmptyState(title: "Loading Tasks...", subtitle: String.localized(EmptyStateText.loadingSubtitle))
}
#endif
