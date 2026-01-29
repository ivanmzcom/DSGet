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
            // MARK: - Server Section
            Section(String.localized("settings.section.server")) {
                if let server = appViewModel.currentServer {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(server.displayName)
                                .font(.body)
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

            // MARK: - About Section
            Section(String.localized("settings.section.about")) {
                HStack {
                    Text(String.localized("settings.about.version"))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                        .foregroundStyle(.secondary)
                }
            }

            // MARK: - Logout Section
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
                .disabled(isLoggingOut)
            }
        }
        .navigationTitle(String.localized("settings.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        isLoggingOut = false
    }
}
