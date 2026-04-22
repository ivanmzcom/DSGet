#if os(macOS)

import SwiftUI

struct DSGetCommands: Commands {
    let appViewModel: AppViewModel

    var body: some Commands {
        CommandMenu("Downloads") {
            Button(String.localized("tasks.button.addTask")) {
                appViewModel.presentAddTask()
            }
            .keyboardShortcut("n")

            Button(String.localized("quickAction.refresh")) {
                Task { await appViewModel.refreshAll() }
            }
            .keyboardShortcut("r")
        }
    }
}

struct DSGetSettingsSceneView: View {
    let appViewModel: AppViewModel

    @AppStorage(AppConstants.StorageKeys.showActiveDownloadBadge)
    private var showActiveDownloadBadge = true

    @State private var isLoggingOut = false

    var body: some View {
        TabView {
            Form {
                Section("Downloads") {
                    Toggle("Show active download badge", isOn: $showActiveDownloadBadge)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            Form {
                Section("Server") {
                    if let server = appViewModel.currentServer {
                        LabeledContent("Name", value: server.displayName)
                        LabeledContent("Address", value: server.configuration.displayName)
                    } else {
                        Text(String.localized("settings.server.noServer"))
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Session") {
                    Button("Log Out", role: .destructive) {
                        Task { await logout() }
                    }
                    .disabled(isLoggingOut)
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("Account", systemImage: "server.rack")
            }
        }
        .frame(width: 480, height: 320)
        .scenePadding()
    }

    private func logout() async {
        isLoggingOut = true
        await appViewModel.logout()
        isLoggingOut = false
    }
}

#endif
