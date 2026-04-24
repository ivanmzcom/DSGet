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

private enum SettingsServerStatus: Equatable {
    case unknown
    case checking
    case connected(Date)
    case signedOut
    case unavailable(String)
    case noServer

    var isChecking: Bool {
        if case .checking = self {
            return true
        }
        return false
    }

    var title: String {
        switch self {
        case .unknown:
            return String.localized("settings.server.status.unknown")
        case .checking:
            return String.localized("settings.server.status.checking")
        case .connected:
            return String.localized("settings.server.status.connected")
        case .signedOut:
            return String.localized("settings.server.status.signedOut")
        case .unavailable:
            return String.localized("settings.server.status.unavailable")
        case .noServer:
            return String.localized("settings.server.noServer")
        }
    }

    var detail: String {
        switch self {
        case .unknown:
            return String.localized("settings.server.status.unknown.description")
        case .checking:
            return String.localized("settings.server.status.checking.description")
        case .connected:
            return String.localized("settings.server.status.connected.description")
        case .signedOut:
            return String.localized("settings.server.status.signedOut.description")
        case .unavailable(let message):
            return message
        case .noServer:
            return String.localized("settings.server.noServer")
        }
    }

    var systemImage: String {
        switch self {
        case .unknown:
            return "questionmark.circle"
        case .checking:
            return "hourglass"
        case .connected:
            return "checkmark.circle.fill"
        case .signedOut:
            return "person.crop.circle.badge.exclamationmark"
        case .unavailable:
            return "exclamationmark.triangle.fill"
        case .noServer:
            return "server.rack"
        }
    }

    var tint: Color {
        switch self {
        case .unknown, .noServer:
            return .secondary
        case .checking:
            return .accentColor
        case .connected:
            return .green
        case .signedOut, .unavailable:
            return .orange
        }
    }
}

private struct SettingsHeaderView: View {
    let server: Server?
    let status: SettingsServerStatus

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            DSGetIconBadge(systemName: "gearshape.fill", tint: .accentColor, size: 42)

            VStack(alignment: .leading, spacing: 8) {
                Text(String.localized("settings.title"))
                    .font(.largeTitle.weight(.semibold))

                Text(server?.displayName ?? String.localized("settings.server.noServer"))
                    .font(.title3)
                    .foregroundStyle(.secondary)

                SettingsStatusBadge(status: status)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsServerCard: View {
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

private struct SettingsStatusSummary: View {
    let status: SettingsServerStatus

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: status.systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(status.tint)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                    .font(.subheadline.weight(.semibold))

                Text(status.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsgetSurface(.row, tint: status.tint)
    }
}

private struct SettingsStatusBadge: View {
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

private struct SettingsRecentServersCard: View {
    let servers: [Server]
    let clearHistory: () async -> Void

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.recentServers"), systemImage: "clock.arrow.circlepath") {
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
                .buttonStyle(.bordered)
                .accessibilityIdentifier(AccessibilityID.Settings.clearServerHistoryButton)
            }
        }
    }
}

private struct SettingsRecentServerRow: View {
    let server: Server

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
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dsgetSurface(.row)
    }

    private var recentServerDetail: String {
        if let lastConnectedAt = server.lastConnectedAt {
            return "\(server.configuration.displayName) - \(settingsRelativeDate(lastConnectedAt))"
        }

        return server.configuration.displayName
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
    let session: Session?
    let isRefreshingSession: Bool
    let isLoggingOut: Bool
    let refreshSession: () async -> Void
    let logout: () async -> Void

    var body: some View {
        AdaptiveSectionCard(String.localized("settings.section.session"), systemImage: "person.crop.circle") {
            Text(String.localized("settings.session.description"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            SettingsSessionSummary(session: session)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    refreshButton
                    logoutButton
                }

                VStack(alignment: .leading, spacing: 12) {
                    refreshButton
                    logoutButton
                }
            }
        }
    }

    private var refreshButton: some View {
        Button {
            Task { await refreshSession() }
        } label: {
            HStack {
                if isRefreshingSession {
                    ProgressView()
                }
                Label(String.localized("settings.session.refresh"), systemImage: "arrow.clockwise")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isRefreshingSession || isLoggingOut)
        .accessibilityIdentifier(AccessibilityID.Settings.refreshSessionButton)
    }

    private var logoutButton: some View {
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
        .disabled(isLoggingOut || isRefreshingSession)
        .accessibilityIdentifier(AccessibilityID.Settings.logoutButton)
    }
}

private struct SettingsSessionSummary: View {
    let session: Session?

    var body: some View {
        if let session {
            let mayBeExpired = session.mightBeExpired()

            SettingsMessageSummary(
                title: mayBeExpired
                    ? String.localized("settings.session.status.expired")
                    : String.localized("settings.session.status.active"),
                detail: mayBeExpired
                    ? String.localized("settings.session.status.expired.description")
                    : String.localized("settings.session.status.active.description"),
                systemImage: mayBeExpired ? "clock.badge.exclamationmark" : "checkmark.circle.fill",
                tint: mayBeExpired ? .orange : .green
            )

            SettingsDetailRow(
                title: String.localized("settings.session.started"),
                value: settingsRelativeDate(session.createdAt)
            )
            SettingsDetailRow(title: String.localized("settings.session.server"), value: session.serverInfo)
        } else {
            SettingsMessageSummary(
                title: String.localized("settings.session.status.signedOut"),
                detail: String.localized("settings.session.status.signedOut.description"),
                systemImage: "person.crop.circle.badge.exclamationmark",
                tint: .orange
            )
        }
    }
}

private struct SettingsMessageSummary: View {
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

private func settingsRelativeDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}
