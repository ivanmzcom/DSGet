//
//  SettingsServerCard.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsServerCard: View {
    let server: Server?
    let status: SettingsServerStatus
    let testConnection: () async -> Void

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.server"), systemImage: "server.rack") {
            if let server {
                SettingsStatusSummary(status: status)

                SettingsDetailRow(
                    title: String.localized("settings.detail.name"),
                    value: server.displayName,
                    accessibilityIdentifier: AccessibilityID.Settings.serverName
                )
                SettingsDetailRow(title: String.localized("settings.detail.address"), value: server.configuration.displayName)
                SettingsDetailRow(title: String.localized("settings.detail.security"), value: server.configuration.useHTTPS ? "HTTPS" : "HTTP")

                if let lastConnectedAt = server.lastConnectedAt {
                    SettingsDetailRow(
                        title: String.localized("settings.detail.lastConnected"),
                        value: settingsRelativeDate(lastConnectedAt)
                    )
                }

                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        if status.isChecking {
                            ProgressView()
                        }
                        Label(String.localized("settings.connection.test"), systemImage: "network")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(status.isChecking)
                .accessibilityIdentifier(AccessibilityID.Settings.testConnectionButton)
            } else {
                SettingsStatusSummary(status: .noServer)
            }
        }
    }
}
