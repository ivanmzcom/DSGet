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
    @State private var appViewModel = AppViewModel()

    /// Tracks whether the login sheet should be shown.
    /// Using a separate State prevents SwiftUI binding issues with computed properties.
    @State private var showLoginSheet = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(appViewModel)

                if appViewModel.isCheckingAuth {
                    loadingOverlay
                }
            }
            .onChange(of: appViewModel.isLoggedIn) { _, isLoggedIn in
                showLoginSheet = !isLoggedIn && !appViewModel.isCheckingAuth
            }
            .onChange(of: appViewModel.isCheckingAuth) { _, isCheckingAuth in
                showLoginSheet = !appViewModel.isLoggedIn && !isCheckingAuth
            }
            .onAppear {
                // Initial state check
                showLoginSheet = !appViewModel.isLoggedIn && !appViewModel.isCheckingAuth
            }
            .sheet(isPresented: $showLoginSheet) {
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
