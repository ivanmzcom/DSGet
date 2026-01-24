import Foundation

/// Represents an authenticated session.
struct Session: Equatable, Sendable {
    let sessionID: String
    let serverConfiguration: ServerConfiguration
    let createdAt: Date

    init(
        sessionID: String,
        serverConfiguration: ServerConfiguration,
        createdAt: Date = Date()
    ) {
        self.sessionID = sessionID
        self.serverConfiguration = serverConfiguration
        self.createdAt = createdAt
    }

    /// Whether the session might be expired (heuristic based on time).
    func mightBeExpired(maxAge: TimeInterval = 24 * 60 * 60) -> Bool {
        Date().timeIntervalSince(createdAt) > maxAge
    }

    /// Age of the session.
    var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Whether the session has a valid session ID.
    var isValid: Bool {
        !sessionID.isEmpty
    }

    /// Server info string for display.
    var serverInfo: String {
        let host = serverConfiguration.host
        let port = serverConfiguration.port
        return "\(host):\(port)"
    }
}

/// Login credentials.
struct Credentials: Equatable, Sendable {
    let username: String
    let password: String
    let otpCode: String?

    init(username: String, password: String, otpCode: String? = nil) {
        self.username = username
        self.password = password
        self.otpCode = otpCode
    }

    /// Creates new credentials with OTP code.
    func withOTP(_ code: String) -> Credentials {
        Credentials(username: username, password: password, otpCode: code)
    }

    /// Creates new credentials without OTP code.
    func withoutOTP() -> Credentials {
        Credentials(username: username, password: password, otpCode: nil)
    }
}

/// Login request parameters.
struct LoginRequest: Equatable, Sendable {
    let configuration: ServerConfiguration
    let credentials: Credentials

    init(configuration: ServerConfiguration, credentials: Credentials) {
        self.configuration = configuration
        self.credentials = credentials
    }
}
