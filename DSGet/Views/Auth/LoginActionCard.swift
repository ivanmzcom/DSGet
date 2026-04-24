//
//  LoginActionCard.swift
//  DSGet
//

import SwiftUI

struct LoginActionCard: View {
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
