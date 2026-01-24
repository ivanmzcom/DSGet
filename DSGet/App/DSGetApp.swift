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

    private var showLoginSheet: Binding<Bool> {
        Binding(
            get: { !appViewModel.isLoggedIn && !appViewModel.isCheckingAuth },
            set: { _ in }
        )
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(appViewModel)

                if appViewModel.isCheckingAuth {
                    loadingOverlay
                }
            }
            .sheet(isPresented: showLoginSheet) {
                LoginView(isLoggedIn: Binding(
                    get: { appViewModel.isLoggedIn },
                    set: { appViewModel.isLoggedIn = $0 }
                ))
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
                Section(header: Text("OTP Required")) {
                    Text("Your session has expired and OTP is required to re-authenticate.")
                    SecureField("OTP Code", text: $otpCode)
                        .textContentType(.oneTimeCode)
                }
                Section {
                    Button("Submit") {
                        if !otpCode.isEmpty {
                            otpService.submit(otp: otpCode)
                            otpCode = ""
                        }
                    }
                    .disabled(otpCode.isEmpty)
                    Button("Cancel", role: .cancel) {
                        otpService.cancel()
                        otpCode = ""
                    }
                }
            }
            .navigationTitle("Enter OTP")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
