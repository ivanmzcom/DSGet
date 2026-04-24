#if os(macOS)

import SwiftUI
import DSGetCore

struct DSGetCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    let appViewModel: AppViewModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button(String.localized("tasks.button.addTask")) {
                appViewModel.presentAddTask()
            }
            .keyboardShortcut("n")
        }

        CommandMenu(String.localized("tab.downloads")) {
            Button(String.localized("quickAction.refresh")) {
                Task { await appViewModel.refreshAll() }
            }
            .keyboardShortcut("r")

            Divider()

            Button(selectedTaskToggleTitle) {
                toggleSelectedTask()
            }
            .disabled(!canToggleSelectedTask)

            Button(String.localized("mac.command.openTaskDetail")) {
                openSelectedTaskDetail()
            }
            .disabled(selectedTask == nil)

            Button(String.localized("mac.command.clearFilters")) {
                appViewModel.tasksViewModel.clearAllFilters()
            }
        }
    }

    private var selectedTask: DownloadTask? {
        appViewModel.tasksViewModel.selectedTask
    }

    private var selectedTaskToggleTitle: String {
        if selectedTask?.isPaused == true {
            String.localized("taskItem.action.resume")
        } else {
            String.localized("taskItem.action.pause")
        }
    }

    private var canToggleSelectedTask: Bool {
        guard let selectedTask else { return false }
        return selectedTask.status.canPause || selectedTask.status.canResume
    }

    private func toggleSelectedTask() {
        guard let selectedTask else { return }
        Task { await appViewModel.tasksViewModel.togglePause(selectedTask) }
    }

    private func openSelectedTaskDetail() {
        guard let selectedTask else { return }
        openWindow(value: selectedTask.id)
    }
}

struct DSGetSettingsSceneView: View {
    let appViewModel: AppViewModel

    @AppStorage(AppConstants.StorageKeys.showActiveDownloadBadge)
    private var showActiveDownloadBadge = true

    @State private var isLoggingOut = false
    @State private var isTestingConnection = false
    @State private var isRefreshingSession = false
    @State private var connectionStatusMessage: String?
    @State private var connectionStatusSucceeded: Bool?
    @State private var currentSession: Session?
    @State private var recentServers: [Server] = []

    var body: some View {
        TabView {
            Form {
                Section(String.localized("tab.downloads")) {
                    Toggle(String.localized("settings.badge.showActiveDownload"), isOn: $showActiveDownloadBadge)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label(String.localized("settings.section.general"), systemImage: "gearshape")
            }

            Form {
                Section(String.localized("settings.section.server")) {
                    if let server = appViewModel.currentServer {
                        LabeledContent(String.localized("settings.detail.name"), value: server.displayName)
                        LabeledContent(String.localized("settings.detail.address"), value: server.configuration.displayName)
                        LabeledContent(String.localized("settings.detail.security"), value: server.configuration.useHTTPS ? "HTTPS" : "HTTP")

                        if let connectionStatusMessage {
                            Label(
                                connectionStatusMessage,
                                systemImage: connectionStatusSucceeded == true ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(connectionStatusSucceeded == true ? .green : .orange)
                        }

                        Button {
                            Task { await testConnection() }
                        } label: {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                }
                                Text(String.localized("settings.connection.test"))
                            }
                        }
                        .disabled(isTestingConnection)
                        .accessibilityIdentifier(AccessibilityID.Settings.testConnectionButton)
                    } else {
                        Text(String.localized("settings.server.noServer"))
                            .foregroundStyle(.secondary)
                    }
                }

                Section(String.localized("settings.section.session")) {
                    if let currentSession {
                        LabeledContent(
                            String.localized("settings.session.started"),
                            value: macSettingsRelativeDate(currentSession.createdAt)
                        )
                        LabeledContent(String.localized("settings.session.server"), value: currentSession.serverInfo)
                    } else {
                        Text(String.localized("settings.session.status.signedOut.description"))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task { await refreshSession() }
                    } label: {
                        HStack {
                            if isRefreshingSession {
                                ProgressView()
                            }
                            Text(String.localized("settings.session.refresh"))
                        }
                    }
                    .disabled(isRefreshingSession || isLoggingOut)
                    .accessibilityIdentifier(AccessibilityID.Settings.refreshSessionButton)

                    Button(String.localized("settings.logout.button"), role: .destructive) {
                        Task { await logout() }
                    }
                    .disabled(isLoggingOut)
                }

                Section(String.localized("settings.section.recentServers")) {
                    if recentServers.isEmpty {
                        Text(String.localized("settings.recentServers.empty"))
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(recentServers) { server in
                            LabeledContent(server.displayName, value: server.configuration.displayName)
                        }

                        Button(String.localized("settings.recentServers.clear"), role: .destructive) {
                            Task { await clearServerHistory() }
                        }
                        .accessibilityIdentifier(AccessibilityID.Settings.clearServerHistoryButton)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label(String.localized("settings.section.account"), systemImage: "server.rack")
            }
        }
        .frame(width: 520, height: 420)
        .scenePadding()
        .task {
            await loadAccountState()
        }
    }

    private func loadAccountState() async {
        currentSession = appViewModel.currentSession()
        recentServers = await appViewModel.recentServers()
    }

    private func testConnection() async {
        isTestingConnection = true
        defer { isTestingConnection = false }

        do {
            try await appViewModel.testCurrentServerConnection()
            currentSession = try await appViewModel.validateCurrentSession()
            connectionStatusSucceeded = true
            connectionStatusMessage = String.localized("settings.server.status.connected")
        } catch {
            connectionStatusSucceeded = false
            connectionStatusMessage = DSGetError.from(error).localizedDescription
        }
    }

    private func refreshSession() async {
        isRefreshingSession = true
        defer { isRefreshingSession = false }

        do {
            currentSession = try await appViewModel.refreshCurrentSession()
            connectionStatusSucceeded = true
            connectionStatusMessage = String.localized("settings.session.status.active")
        } catch {
            connectionStatusSucceeded = false
            connectionStatusMessage = DSGetError.from(error).localizedDescription
        }
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        currentSession = nil
        connectionStatusSucceeded = nil
        connectionStatusMessage = nil
        recentServers = await appViewModel.recentServers()
        isLoggingOut = false
    }

    private func clearServerHistory() async {
        await appViewModel.clearServerHistory()
        recentServers = []
    }
}

private func macSettingsRelativeDate(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

#endif
