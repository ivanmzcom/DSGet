//
//  LoginView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 25/9/25.
//

import SwiftUI
import DSGetCore

struct LoginView: View {
    @State private var viewModel = LoginViewModel()
    @FocusState private var focusedField: LoginField?

    let onLoginSuccess: () -> Void

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    TextField(String.localized("auth.login.placeholder.ipAddress"), text: $viewModel.host)
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

                    TextField(String.localized("auth.login.placeholder.username"), text: $viewModel.username)
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
                        .accessibilityIdentifier(AccessibilityID.Login.passwordField)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        #if !os(macOS)
                        .submitLabel(.next)
                        #endif
                        .onSubmit { focusedField = .otp }

                    LoginValidationMessage(text: viewModel.passwordValidationMessage)

                    SecureField(String.localized("auth.login.placeholder.otp"), text: $viewModel.otpCode)
                        .accessibilityIdentifier(AccessibilityID.Login.otpField)
                        .textContentType(.oneTimeCode)
                        #if !os(macOS)
                        .keyboardType(.numberPad)
                        #endif
                        .focused($focusedField, equals: .otp)

                    if !viewModel.recentServers.isEmpty {
                        Menu {
                            ForEach(viewModel.recentServers) { server in
                                Button {
                                    viewModel.applyRecentServer(server)
                                } label: {
                                    Label(
                                        server.displayName,
                                        systemImage: server.configuration.useHTTPS ? "lock.fill" : "network"
                                    )
                                }
                            }
                        } label: {
                            Label(String.localized("auth.login.recentServers"), systemImage: "clock.arrow.circlepath")
                        }
                        .accessibilityIdentifier(AccessibilityID.Login.recentServersMenu)
                    }

                    Toggle(String.localized("auth.login.toggle.https"), isOn: $viewModel.useHTTPS)
                        .accessibilityIdentifier(AccessibilityID.Login.httpsToggle)

                    TextField(
                        String.localized("auth.login.placeholder.port"),
                        text: Binding(
                            get: { viewModel.portString },
                            set: { viewModel.portString = $0 }
                        )
                    )
                    .accessibilityIdentifier(AccessibilityID.Login.portField)
                    #if !os(macOS)
                    .keyboardType(.numberPad)
                    #endif
                    .focused($focusedField, equals: .port)

                    LoginValidationMessage(text: viewModel.portValidationMessage)

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
                    .accessibilityIdentifier(AccessibilityID.Login.testConnectionButton)
                    .disabled(!viewModel.isServerConfigurationValid || viewModel.connectionTestState.isTesting || viewModel.isLoading)

                    LoginConnectionStatusRow(state: viewModel.connectionTestState)

                    Button {
                        Task { await login() }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
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
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                }
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

    private func login() async {
        viewModel.onLoginSuccess = {
            onLoginSuccess()
        }
        await viewModel.login()
    }
}

#Preview {
    LoginView {}
}

private struct LoginConnectionStatusRow: View {
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
