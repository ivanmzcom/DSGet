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
        Form {
            SettingsServerCard(
                server: appViewModel.currentServer,
                status: serverStatus,
                testConnection: checkCurrentServer
            )

            SettingsSessionCard(
                session: currentSession,
                isRefreshingSession: isRefreshingSession,
                isLoggingOut: isLoggingOut,
                refreshSession: refreshSession,
                logout: logout
            )

            SettingsRecentServersCard(
                servers: recentServers,
                clearHistory: clearServerHistory
            )

            SettingsAboutCard()
        }
        .navigationTitle(String.localized("settings.title"))
        .task {
            await loadSettingsState()
        }
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
