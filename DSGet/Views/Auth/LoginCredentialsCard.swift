//
//  LoginCredentialsCard.swift
//  DSGet
//

import SwiftUI

struct LoginCredentialsCard: View {
    let viewModel: LoginViewModel
    @FocusState.Binding var focusedField: LoginField?

    var body: some View {
        @Bindable var viewModel = viewModel

        Section(String.localized("auth.login.section.credentials")) {
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
        }
    }
}
