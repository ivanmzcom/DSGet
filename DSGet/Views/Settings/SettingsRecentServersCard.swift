//
//  SettingsRecentServersCard.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsRecentServersCard: View {
    let servers: [Server]
    let clearHistory: () async -> Void

    var body: some View {
        Section(String.localized("settings.section.recentServers")) {
            if servers.isEmpty {
                Text(String.localized("settings.recentServers.empty"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(servers) { server in
                        SettingsRecentServerRow(server: server)
                    }
                }

                Button(role: .destructive) {
                    Task { await clearHistory() }
                } label: {
                    Label(String.localized("settings.recentServers.clear"), systemImage: "trash")
                }
                .accessibilityIdentifier(AccessibilityID.Settings.clearServerHistoryButton)
            }
        }
    }
}

private struct SettingsRecentServerRow: View {
    let server: Server

    private var recentServerDetail: String {
        if let lastConnectedAt = server.lastConnectedAt {
            return "\(server.configuration.displayName) - \(settingsRelativeDate(lastConnectedAt))"
        }

        return server.configuration.displayName
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: server.configuration.useHTTPS ? "lock.fill" : "network")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(server.displayName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(recentServerDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
