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
                Section(header: Text("Server Details")) {
                    TextField("Server Name (optional)", text: $viewModel.serverName)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .serverName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .host }

                    TextField("IP or address", text: $viewModel.host)
                        .textContentType(.URL)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .focused($focusedField, equals: .host)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .port }

                    HStack {
                        Toggle("Use HTTPS", isOn: $viewModel.useHTTPS)
                        TextField("Port", text: Binding(
                            get: { viewModel.portString },
                            set: { viewModel.portString = $0 }
                        ))
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                            .keyboardType(.numberPad)
                            .focused($focusedField, equals: .port)
                    }
                }

                Section(header: Text("Credentials")) {
                    TextField("Username", text: $viewModel.username)
                        .textContentType(.username)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .otp }

                    SecureField("OTP (if enabled)", text: $viewModel.otpCode)
                        .textContentType(.oneTimeCode)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .otp)
                }

                Section {
                    Button(action: {
                        Task { await login() }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Text("Login")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading || !viewModel.isFormValid)
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Connect to your Synology Download Station")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
            }
            .navigationTitle("DSGet")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Login Failed", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.currentError?.localizedDescription ?? "An unknown error occurred.")
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
