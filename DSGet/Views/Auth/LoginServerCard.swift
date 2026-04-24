//
//  LoginServerCard.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct LoginServerCard: View {
    let viewModel: LoginViewModel
    @FocusState.Binding var focusedField: LoginField?

    var body: some View {
        @Bindable var viewModel = viewModel

        AdaptiveSectionCard(String.localized("auth.login.section.serverDetails"), systemImage: "server.rack") {
            if !viewModel.recentServers.isEmpty {
                LoginRecentServersMenu(servers: viewModel.recentServers) { server in
                    viewModel.applyRecentServer(server)
                }
            }

            TextField(String.localized("auth.login.placeholder.serverName"), text: $viewModel.serverName)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Login.serverNameField)
                .autocorrectionDisabled(true)
                #if !os(macOS)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                #endif
                .focused($focusedField, equals: .serverName)
                .onSubmit { focusedField = .host }

            TextField(String.localized("auth.login.placeholder.ipAddress"), text: $viewModel.host)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Login.hostField)
                .textContentType(.URL)
                .autocorrectionDisabled(true)
                #if !os(macOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .submitLabel(.next)
                #endif
                .focused($focusedField, equals: .host)
                .onSubmit { focusedField = .port }

            LoginValidationMessage(text: viewModel.hostValidationMessage)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    Toggle(String.localized("auth.login.toggle.https"), isOn: $viewModel.useHTTPS)
                        .accessibilityIdentifier(AccessibilityID.Login.httpsToggle)

                    LoginPortField(viewModel: viewModel, focusedField: $focusedField)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle(String.localized("auth.login.toggle.https"), isOn: $viewModel.useHTTPS)
                        .accessibilityIdentifier(AccessibilityID.Login.httpsToggle)

                    LoginPortField(viewModel: viewModel, focusedField: $focusedField)
                }
            }

            LoginValidationMessage(text: viewModel.portValidationMessage)
            LoginConnectionTestView(viewModel: viewModel)
        }
    }
}

private struct LoginPortField: View {
    let viewModel: LoginViewModel
    @FocusState.Binding var focusedField: LoginField?

    var body: some View {
        TextField(
            String.localized("auth.login.placeholder.port"),
            text: Binding(
                get: { viewModel.portString },
                set: { viewModel.portString = $0 }
            )
        )
        .textFieldStyle(.roundedBorder)
        .accessibilityIdentifier(AccessibilityID.Login.portField)
        #if !os(macOS)
        .keyboardType(.numberPad)
        #endif
        .focused($focusedField, equals: .port)
    }
}

private struct LoginRecentServersMenu: View {
    let servers: [Server]
    let select: (Server) -> Void

    var body: some View {
        Menu {
            ForEach(servers) { server in
                Button {
                    select(server)
                } label: {
                    Label(server.displayName, systemImage: server.configuration.useHTTPS ? "lock.fill" : "network")
                }
            }
        } label: {
            Label(String.localized("auth.login.recentServers"), systemImage: "clock.arrow.circlepath")
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(AccessibilityID.Login.recentServersMenu)
    }
}

private struct LoginConnectionTestView: View {
    let viewModel: LoginViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Task { await viewModel.testConnection() }
            } label: {
                HStack {
                    if viewModel.connectionTestState.isTesting {
                        ProgressView()
                    }

                    Label(String.localized("auth.login.connection.test"), systemImage: "network")
                }
            }
            .buttonStyle(.bordered)
            .disabled(!viewModel.isServerConfigurationValid || viewModel.connectionTestState.isTesting || viewModel.isLoading)
            .accessibilityIdentifier(AccessibilityID.Login.testConnectionButton)

            LoginConnectionStatusView(state: viewModel.connectionTestState)
        }
    }
}

private struct LoginConnectionStatusView: View {
    let state: LoginConnectionTestState

    var body: some View {
        switch state {
        case .idle:
            EmptyView()

        case .testing:
            LoginStatusMessage(
                title: String.localized("auth.login.connection.testing"),
                detail: String.localized("auth.login.connection.testing.description"),
                systemImage: "hourglass",
                tint: .secondary
            )

        case .success:
            LoginStatusMessage(
                title: String.localized("auth.login.connection.success"),
                detail: String.localized("auth.login.connection.success.description"),
                systemImage: "checkmark.circle.fill",
                tint: .green
            )

        case .failure(let message):
            LoginStatusMessage(
                title: String.localized("auth.login.connection.failure"),
                detail: message,
                systemImage: "exclamationmark.triangle.fill",
                tint: .orange
            )
        }
    }
}
