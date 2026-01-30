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
        List {
            serverSection
            aboutSection
            logoutSection
        }
        .navigationTitle(String.localized("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    @ViewBuilder
    private var serverSection: some View {
        Section(String.localized("settings.section.server")) {
            if let server = appViewModel.currentServer {
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.displayName)
                            .font(.body)
                            .accessibilityIdentifier(AccessibilityID.Settings.serverName)
                        Text(server.configuration.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Image(systemName: "server.rack")
                        .foregroundStyle(.secondary)
                    Text(String.localized("settings.server.noServer"))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section(String.localized("settings.section.about")) {
            HStack {
                Text(String.localized("settings.about.version"))
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var logoutSection: some View {
        Section {
            Button(role: .destructive) {
                Task { await logout() }
            } label: {
                HStack {
                    if isLoggingOut {
                        ProgressView()
                    }
                    Text(String.localized("settings.logout.button"))
                }
            }
            .accessibilityIdentifier(AccessibilityID.Settings.logoutButton)
            .disabled(isLoggingOut)
        }
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        isLoggingOut = false
    }
}
