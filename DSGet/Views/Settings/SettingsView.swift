//
//  SettingsView.swift
//  DSGet
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var isLoggingOut = false

    var body: some View {
        List {
            // MARK: - Server Section
            Section("Server") {
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
                        Text("No server")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: - About Section
            Section("About") {
                HStack {
                    Text("Version")
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
                        Text("Logout")
                    }
                }
                .disabled(isLoggingOut)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        isLoggingOut = false
    }
}
