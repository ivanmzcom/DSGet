//
//  KeyboardShortcuts.swift
//  DSGet
//
//  Centralized keyboard shortcuts support.
//

import SwiftUI

// MARK: - Keyboard Shortcut Identifiers

enum KeyboardShortcutAction: String {
    case newTask = "com.dsget.newTask"
    case refresh = "com.dsget.refresh"
    case settings = "com.dsget.settings"
}

// MARK: - Focus Management

enum AppFocusField: Hashable {
    case urlField
    case none
}

// MARK: - Keyboard Shortcuts Overlay View

struct KeyboardShortcutsOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(String.localized("keyboardShortcuts.title"))
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                ShortcutSection(title: String.localized("settings.section.general")) {
                    ShortcutRow(key: "N", modifiers: "\u{2318}", action: String.localized("keyboardShortcuts.newTask"))
                    ShortcutRow(key: "R", modifiers: "\u{2318}", action: String.localized("quickAction.refresh"))
                    ShortcutRow(key: ",", modifiers: "\u{2318}", action: String.localized("tab.settings"))
                }

                ShortcutSection(title: String.localized("keyboardShortcuts.navigation")) {
                    ShortcutRow(key: "\u{21E5}", modifiers: "", action: String.localized("keyboardShortcuts.nextField"))
                    ShortcutRow(key: "\u{21A9}", modifiers: "", action: String.localized("keyboardShortcuts.confirm"))
                    ShortcutRow(key: "\u{238B}", modifiers: "", action: String.localized("keyboardShortcuts.cancelClose"))
                }
            }
        }
        .padding(DSGetDesign.cardPadding)
        .frame(width: 300)
        .dsgetSurface(.card)
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

private struct ShortcutSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

private struct ShortcutRow: View {
    let key: String
    let modifiers: String
    let action: String

    var body: some View {
        HStack {
            Text(action)
                .font(.subheadline)
            Spacer()
            HStack(spacing: 2) {
                if !modifiers.isEmpty {
                    Text(modifiers)
                        .font(.system(.caption, design: .rounded))
                }
                Text(key)
                    .font(.system(.caption, design: .rounded, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius - 2, style: .continuous))
        }
    }
}

// MARK: - Escape Key Handler

extension View {
    func onEscapeKey(_ action: @escaping () -> Void) -> some View {
        self
    }
}
