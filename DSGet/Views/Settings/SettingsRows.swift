//
//  SettingsRows.swift
//  DSGet
//

import SwiftUI

struct SettingsStatusSummary: View {
    let status: SettingsServerStatus

    var body: some View {
        SettingsMessageSummary(
            title: status.title,
            detail: status.detail,
            systemImage: status.systemImage,
            tint: status.tint
        )
    }
}

struct SettingsStatusBadge: View {
    let status: SettingsServerStatus

    var body: some View {
        Label(status.title, systemImage: status.systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(status.tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(status.tint.opacity(0.12), in: Capsule())
    }
}

struct SettingsMessageSummary: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsgetSurface(.row, tint: tint)
    }
}

struct SettingsDetailRow: View {
    let title: String
    let value: String
    var accessibilityIdentifier: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .foregroundStyle(.primary)
                .accessibilityIdentifier(accessibilityIdentifier ?? "")
        }
    }
}
