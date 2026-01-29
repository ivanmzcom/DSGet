//
//  LoginViewModel.swift
//  DSGet
//
//  ViewModel for the login view, handling authentication with Synology NAS.
//

import Foundation
import SwiftUI
import DSGetCore

// MARK: - LoginViewModel

/// ViewModel that manages the state and logic for user authentication.
@MainActor
@Observable
final class LoginViewModel: DomainErrorHandling {
    // MARK: - Published State

    /// Server name (user-friendly label).
    var serverName: String = ""

    /// Server host address.
    var host: String = ""

    /// Server port.
    var port: Int = 5001

    /// Whether to use HTTPS.
    var useHTTPS: Bool = true

    /// Username for authentication.
    var username: String = ""

    /// Password for authentication.
    var password: String = ""

    /// OTP code if 2FA is enabled.
    var otpCode: String = ""

    /// Whether login is in progress.
    private(set) var isLoading: Bool = false

    /// Current error.
    var currentError: DSGetError?

    /// Whether to show error alert.
    var showingError: Bool = false

    // MARK: - Callbacks

    /// Called when login is successful.
    var onLoginSuccess: (() -> Void)?

    // MARK: - Computed Properties

    /// Whether the form is valid for submission.
    var isFormValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        port > 0 && port < 65_536
    }

    /// Port as a string for text field binding.
    var portString: String {
        get { port == 0 ? "" : String(port) }
        set {
            if let value = Int(newValue) {
                port = value
            } else if newValue.isEmpty {
                port = 0
            }
        }
    }

    /// Generated server name if user didn't provide one.
    private var effectiveServerName: String {
        if serverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return host
        }
        return serverName
    }

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol

    // MARK: - Initialization

    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? DIService.authService
    }

    // MARK: - Public Methods

    /// Performs login with the current credentials.
    func login() async {
        guard isFormValid else { return }

        isLoading = true
        currentError = nil
        showingError = false

        // Validate port
        guard port > 0 && port < 65_536 else {
            currentError = DSGetError.api(.serverError(code: -1, message: "Port must be a valid number between 1 and 65535."))
            showingError = true
            isLoading = false
            return
        }

        // Build server configuration
        let server = Server.create(
            name: effectiveServerName,
            host: host,
            port: port,
            useHTTPS: useHTTPS
        )

        let credentials = Credentials(
            username: username,
            password: password,
            otpCode: otpCode.isEmpty ? nil : otpCode
        )

        do {
            // AuthService handles login and saves server
            let loginRequest = LoginRequest(configuration: server.configuration, credentials: credentials)
            _ = try await authService.login(request: loginRequest)

            // Save server info
            try await authService.saveServer(server, credentials: credentials)

            isLoading = false
            onLoginSuccess?()
        } catch {
            handleError(error)
            isLoading = false
        }
    }

    /// Resets the form to default state.
    func reset() {
        password = ""
        otpCode = ""
        currentError = nil
        showingError = false
    }
}
