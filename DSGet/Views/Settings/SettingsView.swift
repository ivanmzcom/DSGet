//
//  SettingsView.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var isLoggingOut = false
    @State private var isCheckingConnection = false
    @State private var serverStatus: SettingsServerStatus = .unknown

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        Form {
            serverSection
            accountSection
            appSection
        }
        .navigationTitle(String.localized("settings.title"))
        #if os(macOS)
        .formStyle(.grouped)
        #endif
        .task {
            await loadSettingsState()
        }
    }

    @ViewBuilder
    private var serverSection: some View {
        Section(String.localized("settings.section.server")) {
            if let server = appViewModel.currentServer {
                Label {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(server.displayName)
                            .font(.headline)
                            .accessibilityIdentifier(AccessibilityID.Settings.serverName)
                        Text(serverStatus.title)
                            .font(.subheadline)
                            .foregroundStyle(serverStatus.tint)
                    }
                } icon: {
                    Image(systemName: serverStatus.systemImage)
                        .foregroundStyle(serverStatus.tint)
                }

                LabeledContent(String.localized("settings.detail.address"), value: server.configuration.displayName)
                LabeledContent(String.localized("settings.detail.security"), value: server.configuration.useHTTPS ? "HTTPS" : "HTTP")

                Button {
                    Task { await checkCurrentServer() }
                } label: {
                    HStack {
                        if isCheckingConnection {
                            ProgressView()
                        }
                        Label(String.localized("settings.connection.test"), systemImage: "network")
                    }
                }
                .disabled(isCheckingConnection)
                .accessibilityIdentifier(AccessibilityID.Settings.testConnectionButton)
            } else {
                Label(String.localized("settings.server.noServer"), systemImage: "server.rack")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var accountSection: some View {
        Section(String.localized("settings.section.account")) {
            Button(role: .destructive) {
                Task { await logout() }
            } label: {
                HStack {
                    if isLoggingOut {
                        ProgressView()
                    }
                    Label(String.localized("settings.logout.button"), systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            .disabled(isLoggingOut)
            .accessibilityIdentifier(AccessibilityID.Settings.logoutButton)
        }
    }

    private var appSection: some View {
        Section(String.localized("settings.section.about")) {
            LabeledContent(String.localized("settings.about.version"), value: appVersion)
        }
    }

    private func loadSettingsState() async {
        await checkCurrentServer()
    }

    private func checkCurrentServer() async {
        guard appViewModel.currentServer != nil else {
            serverStatus = .noServer
            return
        }

        guard !isCheckingConnection else { return }

        isCheckingConnection = true
        serverStatus = .checking
        defer { isCheckingConnection = false }

        do {
            try await appViewModel.testCurrentServerConnection()
            serverStatus = .connected(Date())
        } catch {
            serverStatus = .unavailable(DSGetError.from(error).localizedDescription)
        }
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        serverStatus = .noServer
        isLoggingOut = false
    }
}
