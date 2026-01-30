//
//  LoginView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 25/9/25.
//

import SwiftUI
import DSGetCore

struct LoginView: View {
    @Binding var isLoggedIn: Bool

    @State private var viewModel = LoginViewModel()

    @FocusState private var focusedField: LoginField?

    private enum LoginField: Hashable {
        case serverName, host, port, username, password, otp
    }

    var body: some View {
        NavigationStack {
            Form {
                serverDetailsSection
                credentialsSection
                loginButtonSection
                subtitleSection
            }
            .navigationTitle(String.localized("auth.login.title"))
            .navigationBarTitleDisplayMode(.inline)
            .alert(String.localized("auth.login.error.title"), isPresented: $viewModel.showingError) {
                Button(String.localized("general.ok"), role: .cancel) { }
            } message: {
                Text(viewModel.currentError?.localizedDescription ?? String.localized("auth.login.error.unknown"))
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var serverDetailsSection: some View {
        Section(header: Text(String.localized("auth.login.section.serverDetails"))) {
            TextField(String.localized("auth.login.placeholder.serverName"), text: $viewModel.serverName)
                .accessibilityIdentifier(AccessibilityID.Login.serverNameField)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.words)
                .focused($focusedField, equals: .serverName)
                .submitLabel(.next)
                .onSubmit { focusedField = .host }

            TextField(String.localized("auth.login.placeholder.ipAddress"), text: $viewModel.host)
                .accessibilityIdentifier(AccessibilityID.Login.hostField)
                .textContentType(.URL)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .focused($focusedField, equals: .host)
                .submitLabel(.next)
                .onSubmit { focusedField = .port }

            HStack {
                Toggle(String.localized("auth.login.toggle.https"), isOn: $viewModel.useHTTPS)
                    .accessibilityIdentifier(AccessibilityID.Login.httpsToggle)
                TextField(String.localized("auth.login.placeholder.port"), text: Binding(
                    get: { viewModel.portString },
                    set: { viewModel.portString = $0 }
                ))
                    .accessibilityIdentifier(AccessibilityID.Login.portField)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 100)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .port)
            }
        }
    }

    @ViewBuilder
    private var credentialsSection: some View {
        Section(header: Text(String.localized("auth.login.section.credentials"))) {
            TextField(String.localized("auth.login.placeholder.username"), text: $viewModel.username)
                .accessibilityIdentifier(AccessibilityID.Login.usernameField)
                .textContentType(.username)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .focused($focusedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }

            SecureField(String.localized("auth.login.placeholder.password"), text: $viewModel.password)
                .accessibilityIdentifier(AccessibilityID.Login.passwordField)
                .textContentType(.password)
                .focused($focusedField, equals: .password)
                .submitLabel(.next)
                .onSubmit { focusedField = .otp }

            SecureField(String.localized("auth.login.placeholder.otp"), text: $viewModel.otpCode)
                .accessibilityIdentifier(AccessibilityID.Login.otpField)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .otp)
        }
    }

    @ViewBuilder
    private var loginButtonSection: some View {
        Section {
            Button(action: {
                Task { await login() }
            }, label: {
                HStack {
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    } else {
                        Text(String.localized("auth.login.button.login"))
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            })
            .accessibilityIdentifier(AccessibilityID.Login.loginButton)
            .disabled(viewModel.isLoading || !viewModel.isFormValid)
        }
    }

    @ViewBuilder
    private var subtitleSection: some View {
        Section {
            HStack {
                Spacer()
                Text(String.localized("auth.login.subtitle"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
    }

    private func login() async {
        viewModel.onLoginSuccess = {
            isLoggedIn = true
        }
        await viewModel.login()
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedIn: .constant(false))
    }
}
