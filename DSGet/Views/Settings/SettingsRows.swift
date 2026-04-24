//
//  SettingsRows.swift
//  DSGet
//

import SwiftUI

struct SettingsStatusSummary: View {
    let status: SettingsServerStatus

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                Text(status.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: status.systemImage)
                .foregroundStyle(status.tint)
        }
    }
}

struct SettingsMessageSummary: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }
}

struct SettingsDetailRow: View {
    let title: String
    let value: String
    var accessibilityIdentifier: String?

    var body: some View {
        LabeledContent(title, value: value)
            .accessibilityIdentifier(accessibilityIdentifier ?? "")
    }
}
