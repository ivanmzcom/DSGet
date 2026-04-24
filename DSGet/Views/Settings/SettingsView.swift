//
//  SettingsView.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appViewModel

    @State private var isLoggingOut = false
    @State private var isRefreshingSession = false
    @State private var serverStatus: SettingsServerStatus = .unknown
    @State private var currentSession: Session?
    @State private var recentServers: [Server] = []

    var body: some View {
        AdaptiveLayoutReader { width in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    SettingsHeaderView(server: appViewModel.currentServer, status: serverStatus)

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
            .task {
                await loadSettingsState()
            }
        }
    }

    private var primaryColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            SettingsServerCard(
                server: appViewModel.currentServer,
                status: serverStatus,
                testConnection: checkCurrentServer
            )

            SettingsRecentServersCard(
                servers: recentServers,
                clearHistory: clearServerHistory
            )

            SettingsAboutCard()
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var secondaryColumn: some View {
        SettingsSessionCard(
            session: currentSession,
            isRefreshingSession: isRefreshingSession,
            isLoggingOut: isLoggingOut,
            refreshSession: refreshSession,
            logout: logout
        )
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func loadSettingsState() async {
        currentSession = appViewModel.currentSession()
        recentServers = await appViewModel.recentServers()
        await checkCurrentServer()
    }

    private func checkCurrentServer() async {
        guard appViewModel.currentServer != nil else {
            currentSession = nil
            serverStatus = .noServer
            return
        }

        serverStatus = .checking

        do {
            try await appViewModel.testCurrentServerConnection()
            currentSession = try await appViewModel.validateCurrentSession()
            serverStatus = currentSession == nil ? .signedOut : .connected(Date())
        } catch {
            serverStatus = .unavailable(DSGetError.from(error).localizedDescription)
        }
    }

    private func refreshSession() async {
        guard !isRefreshingSession else { return }

        isRefreshingSession = true
        defer { isRefreshingSession = false }

        do {
            currentSession = try await appViewModel.refreshCurrentSession()
            serverStatus = .connected(Date())
        } catch {
            serverStatus = .unavailable(DSGetError.from(error).localizedDescription)
        }
    }

    private func clearServerHistory() async {
        await appViewModel.clearServerHistory()
        recentServers = []
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        currentSession = nil
        serverStatus = .noServer
        recentServers = await appViewModel.recentServers()
        isLoggingOut = false
    }
}
