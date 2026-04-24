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

enum LoginConnectionTestState: Equatable {
    case idle
    case testing
    case success(Date)
    case failure(String)

    var isTesting: Bool {
        if case .testing = self {
            return true
        }
        return false
    }
}

/// ViewModel that manages the state and logic for user authentication.
@MainActor
@Observable
final class LoginViewModel: DomainErrorHandling {
    // MARK: - Published State

    /// Server name (user-friendly label).
    var serverName: String = ""

    /// Server host address.
    var host: String = "" {
        didSet {
            guard oldValue != host else { return }
            clearConnectionTest()
        }
    }

    /// Server port.
    var port: Int = ServerConfiguration.defaultHTTPSPort {
        didSet {
            guard oldValue != port else { return }
            clearConnectionTest()
        }
    }

    /// Whether to use HTTPS.
    var useHTTPS: Bool = true {
        didSet {
            guard oldValue != useHTTPS else { return }
            updatePortForSchemeChange(previousUseHTTPS: oldValue)
            clearConnectionTest()
        }
    }

    /// Username for authentication.
    var username: String = ""

    /// Password for authentication.
    var password: String = ""

    /// OTP code if 2FA is enabled.
    var otpCode: String = ""

    /// Whether login is in progress.
    private(set) var isLoading: Bool = false

    /// Whether validation hints should be shown for missing required values.
    private(set) var hasAttemptedValidation: Bool = false

    /// Current connection test state for the server configuration.
    private(set) var connectionTestState: LoginConnectionTestState = .idle

    /// Recently used servers for quick selection.
    private(set) var recentServers: [Server] = []

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
        isServerConfigurationValid &&
            usernameValidationMessage(showRequired: true) == nil &&
            passwordValidationMessage(showRequired: true) == nil
    }

    /// Whether the server details can be tested without credentials.
    var isServerConfigurationValid: Bool {
        hostValidationMessage(showRequired: true) == nil &&
            portValidationMessage(showRequired: true) == nil
    }

    var hostValidationMessage: String? {
        hostValidationMessage(showRequired: hasAttemptedValidation)
    }

    var portValidationMessage: String? {
        portValidationMessage(showRequired: hasAttemptedValidation)
    }

    var usernameValidationMessage: String? {
        usernameValidationMessage(showRequired: hasAttemptedValidation)
    }

    var passwordValidationMessage: String? {
        passwordValidationMessage(showRequired: hasAttemptedValidation)
    }

    var formGuidanceMessage: String? {
        guard !isFormValid else { return nil }

        if hostValidationMessage(showRequired: true) != nil || portValidationMessage(showRequired: true) != nil {
            return String.localized("auth.login.validation.serverSummary")
        }

        return String.localized("auth.login.validation.credentialsSummary")
    }

    /// Port as a string for text field binding.
    var portString: String {
        get { port == 0 ? "" : String(port) }
        set {
            let digits = newValue.filter(\.isNumber)
            if let value = Int(digits) {
                port = value
            } else if digits.isEmpty {
                port = 0
            }
        }
    }

    /// Generated server name if user didn't provide one.
    private var effectiveServerName: String {
        if serverName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return trimmedHost
        }
        return serverName
    }

    private var trimmedHost: String {
        host.trimmingCharacters(in: .whitespacesAndNewlines)
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
        hasAttemptedValidation = true
        guard isFormValid else { return }

        isLoading = true
        currentError = nil
        showingError = false

        // Build server configuration
        let server = Server.create(
            name: effectiveServerName,
            host: trimmedHost,
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
            await loadRecentServers()
            onLoginSuccess?()
        } catch {
            handleError(error)
            isLoading = false
        }
    }

    /// Tests server reachability without attempting to authenticate.
    func testConnection() async {
        hasAttemptedValidation = true

        guard isServerConfigurationValid else {
            connectionTestState = .failure(String.localized("auth.login.connection.invalidServer"))
            return
        }

        connectionTestState = .testing
        currentError = nil
        showingError = false

        do {
            let configuration = ServerConfiguration(host: trimmedHost, port: port, useHTTPS: useHTTPS)
            try await authService.testConnection(configuration: configuration)
            connectionTestState = .success(Date())
        } catch {
            connectionTestState = .failure(DSGetError.from(error).localizedDescription)
        }
    }

    func loadRecentServers() async {
        recentServers = await authService.getRecentServers()
    }

    func applyRecentServer(_ server: Server) {
        serverName = server.name
        host = server.configuration.host
        port = server.configuration.port
        useHTTPS = server.configuration.useHTTPS
        password = ""
        otpCode = ""
        hasAttemptedValidation = false
        connectionTestState = .idle
    }

    /// Resets the form to default state.
    func reset() {
        password = ""
        otpCode = ""
        currentError = nil
        showingError = false
        connectionTestState = .idle
        hasAttemptedValidation = false
    }

    private func updatePortForSchemeChange(previousUseHTTPS: Bool) {
        let previousDefault = previousUseHTTPS ? ServerConfiguration.defaultHTTPSPort : ServerConfiguration.defaultHTTPPort
        let newDefault = useHTTPS ? ServerConfiguration.defaultHTTPSPort : ServerConfiguration.defaultHTTPPort

        if port == previousDefault || port == 0 {
            port = newDefault
        }
    }

    private func clearConnectionTest() {
        if connectionTestState != .idle {
            connectionTestState = .idle
        }
    }

    private func hostValidationMessage(showRequired: Bool) -> String? {
        if trimmedHost.isEmpty {
            return showRequired ? String.localized("auth.login.validation.hostRequired") : nil
        }

        if trimmedHost.contains("://") {
            return String.localized("auth.login.validation.hostNoScheme")
        }

        if trimmedHost.contains("/") {
            return String.localized("auth.login.validation.hostNoPath")
        }

        if ServerConfiguration(host: trimmedHost, port: port, useHTTPS: useHTTPS).baseURL == nil {
            return String.localized("auth.login.validation.hostInvalid")
        }

        return nil
    }

    private func portValidationMessage(showRequired: Bool) -> String? {
        if port == 0 {
            return showRequired ? String.localized("auth.login.validation.portRequired") : nil
        }

        if port < 0 || port >= 65_536 {
            return String.localized("auth.login.validation.portRange")
        }

        return nil
    }

    private func usernameValidationMessage(showRequired: Bool) -> String? {
        if username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return showRequired ? String.localized("auth.login.validation.usernameRequired") : nil
        }

        return nil
    }

    private func passwordValidationMessage(showRequired: Bool) -> String? {
        if password.isEmpty {
            return showRequired ? String.localized("auth.login.validation.passwordRequired") : nil
        }

        return nil
    }
}
