//
//  DSGetApp.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 25/9/25.
//

import SwiftUI
import DSGetCore

@main
struct DSGetApp: App {
    @State private var appViewModel: AppViewModel

    private var loginSheetBinding: Binding<Bool> {
        Binding(
            get: { !appViewModel.isLoggedIn && !appViewModel.isCheckingAuth },
            set: { _ in }
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
        mainWindowScene
        #if os(macOS)
        WindowGroup("Task Detail", for: TaskID.self) { $taskID in
            TaskDetailWindowView(taskID: taskID)
                .environment(appViewModel)
        }
        Settings {
            DSGetSettingsSceneView(appViewModel: appViewModel)
        }
        #endif
    }

    @SceneBuilder
    private var mainWindowScene: some Scene {
        #if os(macOS)
        WindowGroup {
            rootContent
        }
        .commands {
            DSGetCommands(appViewModel: appViewModel)
        }
        #else
        WindowGroup {
            rootContent
        }
        #endif
    }

    private var rootContent: some View {
        AppRootView(appViewModel: appViewModel)
            .environment(appViewModel)
            .sheet(isPresented: loginSheetBinding) {
                LoginView {
                    appViewModel.isLoggedIn = true
                }
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

private struct AppRootView: View {
    let appViewModel: AppViewModel

    var body: some View {
        ZStack {
            #if !os(macOS)
            Color.dsgetWindowBackground
                .ignoresSafeArea()
            #endif

            if appViewModel.isLoggedIn {
                MainView()
            }

            if appViewModel.isCheckingAuth {
                AppLoadingView()
            }
        }
    }
}

private struct AppLoadingView: View {
    var body: some View {
        ProgressView()
            .scaleEffect(1.5)
    }
}

private struct OTPSheetView: View {
    let otpService: OTPService

    @State private var otpCode = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(String.localized("otp.required.title")) {
                    Text(String.localized("otp.required"))
                    SecureField(String.localized("otp.placeholder"), text: $otpCode)
                        .textContentType(.oneTimeCode)
                }
                OTPActionsSection(
                    otpCode: $otpCode,
                    onSubmit: submitOTP,
                    onCancel: cancelOTP
                )
            }
            .navigationTitle(String.localized("otp.title"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    private func submitOTP() {
        guard !otpCode.isEmpty else { return }
        otpService.submit(otp: otpCode)
        otpCode = ""
    }

    private func cancelOTP() {
        otpService.cancel()
        otpCode = ""
    }
}

private struct OTPActionsSection: View {
    @Binding var otpCode: String

    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Section {
            Button(String.localized("otp.button.submit"), action: onSubmit)
                .disabled(otpCode.isEmpty)

            Button(String.localized("otp.button.cancel"), role: .cancel, action: onCancel)
        }
    }
}
