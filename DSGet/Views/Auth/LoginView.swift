//
//  LoginView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 25/9/25.
//

import SwiftUI

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

#Preview {
    LoginView {}
}
