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
        VStack(alignment: .leading, spacing: 8) {
            Text(String.localized("auth.login.title"))
                .font(.largeTitle.weight(.semibold))

            Text(String.localized("auth.login.subtitle"))
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct LoginServerCard: View {
    let viewModel: LoginViewModel
    @FocusState.Binding var focusedField: LoginField?

    var body: some View {
        @Bindable var viewModel = viewModel

        AdaptiveSectionCard(String.localized("auth.login.section.serverDetails"), systemImage: "server.rack") {
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

            SecureField(String.localized("auth.login.placeholder.password"), text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier(AccessibilityID.Login.passwordField)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                #if !os(macOS)
                .submitLabel(.next)
                #endif
                .onSubmit { focusedField = .otp }

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
    let login: () async -> Void

    var body: some View {
        AdaptiveSectionCard("Continue", systemImage: "arrow.right.circle") {
            Button {
                Task { await login() }
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                    } else {
                        Text(String.localized("auth.login.button.login"))
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

#Preview {
    LoginView {}
}
