//
//  SettingsView.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var isLoggingOut = false

    var body: some View {
        AdaptiveLayoutReader { width in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SettingsHeaderView(server: appViewModel.currentServer)

                    if width.usesTwoColumns {
                        HStack(alignment: .top, spacing: 20) {
                            primaryColumn
                            secondaryColumn
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            primaryColumn
                            secondaryColumn
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: width.contentMaxWidth)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .navigationTitle(String.localized("settings.title"))
        }
    }

    private var primaryColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsServerCard(server: appViewModel.currentServer)
            SettingsAboutCard()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var secondaryColumn: some View {
        SettingsSessionCard(isLoggingOut: isLoggingOut, logout: logout)
            .frame(maxWidth: .infinity, alignment: .top)
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        isLoggingOut = false
    }
}

private struct SettingsHeaderView: View {
    let server: Server?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String.localized("settings.title"))
                .font(.largeTitle.weight(.semibold))

            Text(server?.displayName ?? String.localized("settings.server.noServer"))
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsServerCard: View {
    let server: Server?

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.server"), systemImage: "server.rack") {
            if let server {
                SettingsDetailRow(
                    title: "Name",
                    value: server.displayName,
                    accessibilityIdentifier: AccessibilityID.Settings.serverName
                )
                SettingsDetailRow(title: "Address", value: server.configuration.displayName)
            } else {
                Text(String.localized("settings.server.noServer"))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SettingsAboutCard: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.about"), systemImage: "info.circle") {
            SettingsDetailRow(title: String.localized("settings.about.version"), value: appVersion)
        }
    }
}

private struct SettingsSessionCard: View {
    let isLoggingOut: Bool
    let logout: () async -> Void

    var body: some View {
        AdaptiveSectionCard("Session", systemImage: "person.crop.circle") {
            Text("Manage the current connection and sign out when you need to switch servers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                Task { await logout() }
            } label: {
                HStack {
                    if isLoggingOut {
                        ProgressView()
                    }
                    Text(String.localized("settings.logout.button"))
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(isLoggingOut)
            .accessibilityIdentifier(AccessibilityID.Settings.logoutButton)
        }
    }
}

private struct SettingsDetailRow: View {
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
