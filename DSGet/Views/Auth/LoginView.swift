//
//  LoginView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 25/9/25.
//

import SwiftUI
import DSGetCore

fileprivate enum LoginField: Hashable {
    case serverName, host, port, username, password, otp
}

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: LoginField?

    let onLoginSuccess: () -> Void

    var body: some View {
        NavigationStack {
            AdaptiveLayoutReader { width in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        LoginHeaderView()

                        if width.usesTwoColumns {
                            HStack(alignment: .top, spacing: 20) {
                                LoginServerCard(viewModel: viewModel, focusedField: $focusedField)
                                LoginCredentialsCard(viewModel: viewModel, focusedField: $focusedField)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 20) {
                                LoginServerCard(viewModel: viewModel, focusedField: $focusedField)
                                LoginCredentialsCard(viewModel: viewModel, focusedField: $focusedField)
                            }
                        }

                        LoginActionCard(
                            isLoading: viewModel.isLoading,
                            isEnabled: viewModel.isFormValid,
                            guidanceMessage: viewModel.formGuidanceMessage,
                            login: login
                        )
                    }
                    .padding(20)
                    .frame(maxWidth: width.contentMaxWidth)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                .navigationTitle(String.localized("auth.login.title"))
                .alert(String.localized("auth.login.error.title"), isPresented: $viewModel.showingError) {
                    Button(String.localized("general.ok"), role: .cancel) { }
                } message: {
                    Text(viewModel.currentError?.localizedDescription ?? String.localized("auth.login.error.unknown"))
                }
                .task {
                    await viewModel.loadRecentServers()
                }
            }
        }
    }

    private func login() async {
        viewModel.onLoginSuccess = {
            onLoginSuccess()
        }
        await viewModel.login()
    }
}

private struct LoginHeaderView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text(String.localized("auth.login.title"))
                    .font(.largeTitle.weight(.semibold))

                Text(String.localized("auth.login.subtitle"))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LoginServerCard: View {
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

private struct LoginCredentialsCard: View {
    let viewModel: LoginViewModel
    @FocusState.Binding var focusedField: LoginField?

    var body: some View {
        @Bindable var viewModel = viewModel

        AdaptiveSectionCard(String.localized("auth.login.section.credentials"), systemImage: "person.crop.circle") {
            TextField(String.localized("auth.login.placeholder.username"), text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Login.usernameField)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                #if !os(macOS)
                .textInputAutocapitalization(.never)
                .submitLabel(.next)
                #endif
                .focused($focusedField, equals: .username)
                .onSubmit { focusedField = .password }

            LoginValidationMessage(text: viewModel.usernameValidationMessage)

            SecureField(String.localized("auth.login.placeholder.password"), text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Login.passwordField)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                #if !os(macOS)
                .submitLabel(.next)
                #endif
                .onSubmit { focusedField = .otp }

            LoginValidationMessage(text: viewModel.passwordValidationMessage)

            SecureField(String.localized("auth.login.placeholder.otp"), text: $viewModel.otpCode)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Login.otpField)
                .textContentType(.oneTimeCode)
                #if !os(macOS)
                .keyboardType(.numberPad)
                #endif
                .focused($focusedField, equals: .otp)
        }
    }
}

private struct LoginActionCard: View {
    let isLoading: Bool
    let isEnabled: Bool
    let guidanceMessage: String?
    let login: () async -> Void

    var body: some View {
        AdaptiveSectionCard(String.localized("auth.login.section.continue"), systemImage: "arrow.right.circle") {
            if let guidanceMessage {
                LoginStatusMessage(
                    title: String.localized("auth.login.validation.readyTitle"),
                    detail: guidanceMessage,
                    systemImage: "info.circle",
                    tint: .secondary
                )
            }

            Button {
                Task { await login() }
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Label(String.localized("auth.login.button.login"), systemImage: "arrow.right")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier(AccessibilityID.Login.loginButton)
            .disabled(isLoading || !isEnabled)
        }
    }
}

private struct LoginValidationMessage: View {
    let text: String?

    var body: some View {
        if let text {
            Label(text, systemImage: "exclamationmark.circle")
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LoginStatusMessage: View {
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

#Preview {
    LoginView {}
}
