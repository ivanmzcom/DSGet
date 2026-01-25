//
//  AccessibilityModifiers.swift
//  DSGet
//
//  Centralized accessibility modifiers for VoiceOver and Dynamic Type support.
//

import SwiftUI
import DSGetCore

// MARK: - Task Accessibility

extension View {

    /// Applies accessibility labels and hints for a download task item.
    func taskAccessibility(_ task: DownloadTask) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(taskAccessibilityLabel(task))
            .accessibilityValue(taskAccessibilityValue(task))
            .accessibilityHint(Text("Double tap to view details"))
            .accessibilityAddTraits(.isButton)
    }

    private func taskAccessibilityLabel(_ task: DownloadTask) -> Text {
        Text("\(task.title), \(task.status.displayName)")
    }

    private func taskAccessibilityValue(_ task: DownloadTask) -> Text {
        let progress = Int(task.progress * 100)
        var components: [String] = []

        components.append("\(progress) percent complete")

        if task.isDownloading, let speed = task.transfer?.downloadSpeed, speed.bytes > 0 {
            components.append("downloading at \(speed.formatted)")
        }

        if let size = task.size.formatted as String? {
            components.append("size \(size)")
        }

        return Text(components.joined(separator: ", "))
    }
}

// MARK: - Feed Accessibility

extension View {

    /// Applies accessibility labels and hints for a feed item.
    func feedAccessibility(_ feed: RSSFeed, isFavorite: Bool, isRefreshing: Bool) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(feedAccessibilityLabel(feed, isFavorite: isFavorite))
            .accessibilityValue(feedAccessibilityValue(feed, isRefreshing: isRefreshing))
            .accessibilityHint(Text("Double tap to view items"))
            .accessibilityAddTraits(.isButton)
    }

    private func feedAccessibilityLabel(_ feed: RSSFeed, isFavorite: Bool) -> Text {
        if isFavorite {
            return Text("\(feed.title), favorite")
        }
        return Text(feed.title)
    }

    private func feedAccessibilityValue(_ feed: RSSFeed, isRefreshing: Bool) -> Text {
        if isRefreshing {
            return Text("Refreshing")
        }
        if let lastUpdate = feed.lastUpdateFormatted {
            return Text("Last updated \(lastUpdate)")
        }
        return Text("")
    }
}

// MARK: - Progress Accessibility

extension View {

    /// Applies accessibility for a progress indicator.
    func progressAccessibility(value: Double, label: String) -> some View {
        self
            .accessibilityLabel(Text(label))
            .accessibilityValue(Text("\(Int(value * 100)) percent"))
    }
}

// MARK: - Action Button Accessibility

extension View {

    /// Applies accessibility for action buttons.
    func actionButtonAccessibility(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(Text(label))
            .accessibilityHint(hint.map { Text($0) } ?? Text(""))
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Reduce Motion Support

extension View {

    /// Wraps content in animation that respects Reduce Motion setting.
    func animateWithMotionPreference<V: Equatable>(
        value: V,
        animation: Animation = .easeInOut(duration: 0.3)
    ) -> some View {
        modifier(ReduceMotionAnimationModifier(value: value, animation: animation))
    }
}

private struct ReduceMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: V
    let animation: Animation

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : animation, value: value)
    }
}

// MARK: - Dynamic Type Support

extension View {

    /// Ensures view scales appropriately with Dynamic Type.
    func dynamicTypeAccessible() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

// MARK: - Scaled Metrics

/// Scaled spacing value that adapts to Dynamic Type.
@propertyWrapper
struct ScaledSpacing: DynamicProperty {
    @ScaledMetric private var value: CGFloat

    var wrappedValue: CGFloat { value }

    init(wrappedValue: CGFloat) {
        _value = ScaledMetric(wrappedValue: wrappedValue)
    }
}

// MARK: - High Contrast Support

extension View {

    /// Adjusts opacity for high contrast mode.
    func highContrastAdaptive(normalOpacity: Double = 0.6, highContrastOpacity: Double = 1.0) -> some View {
        modifier(HighContrastModifier(normalOpacity: normalOpacity, highContrastOpacity: highContrastOpacity))
    }
}

private struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    @Environment(\.colorSchemeContrast) private var contrast
    let normalOpacity: Double
    let highContrastOpacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(contrast == .increased ? highContrastOpacity : normalOpacity)
    }
}

// MARK: - Rotor Actions

extension View {

    /// Adds custom accessibility actions for VoiceOver rotor.
    func taskRotorActions(
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        isPaused: Bool
    ) -> some View {
        self
            .accessibilityAction(named: isPaused ? "Resume" : "Pause") {
                isPaused ? onResume() : onPause()
            }
            .accessibilityAction(named: "Delete") {
                onDelete()
            }
    }

    /// Adds custom accessibility actions for feed items.
    func feedRotorActions(
        onRefresh: @escaping () -> Void,
        onToggleFavorite: @escaping () -> Void,
        isFavorite: Bool
    ) -> some View {
        self
            .accessibilityAction(named: "Refresh") {
                onRefresh()
            }
            .accessibilityAction(named: isFavorite ? "Remove from favorites" : "Add to favorites") {
                onToggleFavorite()
            }
    }
}
