//
//  DSGetApp.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 25/9/25.
//

import SwiftUI

@main
struct DSGetApp: App {
    /// Main application ViewModel.
    @State private var appViewModel: AppViewModel

    /// Computed binding that shows login only when not authenticated and not checking.
    /// Dismissal is only allowed when the user has actually logged in.
    private var showLoginSheet: Binding<Bool> {
        Binding(
            get: { !appViewModel.isLoggedIn && !appViewModel.isCheckingAuth },
            set: { newValue in
                if !newValue && !appViewModel.isLoggedIn {
                    // Prevent dismissal unless actually logged in
                    return
                }
            }
        )
    }

    init() {
        #if DEBUG
        if CommandLine.arguments.contains("--uitesting") {
            let loggedOut = CommandLine.arguments.contains("--uitesting-logged-out")
            DIContainer.shared.configureForTesting(loggedOut: loggedOut)
        }
        #endif
        _appViewModel = State(initialValue: AppViewModel())
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appViewModel.isLoggedIn {
                    MainView()
                        .environment(appViewModel)
                } else if appViewModel.isCheckingAuth {
                    loadingOverlay
                }
            }
            .sheet(isPresented: showLoginSheet) {
                LoginView(isLoggedIn: $appViewModel.isLoggedIn)
                .interactiveDismissDisabled(true)
            }
            .onOpenURL { url in
                appViewModel.handleIncomingURL(url)
            }
            .sheet(isPresented: Binding(
                get: { appViewModel.otpService.showingSheet },
                set: { appViewModel.otpService.showingSheet = $0 }
            )) {
                OTPSheetView(otpService: appViewModel.otpService)
            }
        }
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color(uiColor: .systemBackground)
            ProgressView()
                .scaleEffect(1.5)
        }
        .ignoresSafeArea()
    }
}

// MARK: - OTP Sheet View

/// Sheet view for OTP input.
struct OTPSheetView: View {
    let otpService: OTPService
    @State private var otpCode = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(String.localized("otp.required.title"))) {
                    Text(String.localized("otp.required"))
                    SecureField(String.localized("otp.placeholder"), text: $otpCode)
                        .textContentType(.oneTimeCode)
                }
                Section {
                    Button(String.localized("otp.button.submit")) {
                        if !otpCode.isEmpty {
                            otpService.submit(otp: otpCode)
                            otpCode = ""
                        }
                    }
                    .disabled(otpCode.isEmpty)
                    Button(String.localized("otp.button.cancel"), role: .cancel) {
                        otpService.cancel()
                        otpCode = ""
                    }
                }
            }
            .navigationTitle(String.localized("otp.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
