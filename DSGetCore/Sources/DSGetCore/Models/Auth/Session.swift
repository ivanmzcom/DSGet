import Foundation

/// Represents an authenticated session.
public struct Session: Equatable, Sendable {
    public let sessionID: String
    public let serverConfiguration: ServerConfiguration
    public let createdAt: Date

    public init(
        sessionID: String,
        serverConfiguration: ServerConfiguration,
        createdAt: Date = Date()
    ) {
        self.sessionID = sessionID
        self.serverConfiguration = serverConfiguration
        self.createdAt = createdAt
    }

    /// Whether the session might be expired (heuristic based on time).
    public func mightBeExpired(maxAge: TimeInterval = 24 * 60 * 60) -> Bool {
        Date().timeIntervalSince(createdAt) > maxAge
    }

    /// Age of the session.
    public var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Whether the session has a valid session ID.
    public var isValid: Bool {
        !sessionID.isEmpty
    }

    /// Server info string for display.
    public var serverInfo: String {
        let host = serverConfiguration.host
        let port = serverConfiguration.port
        return "\(host):\(port)"
    }
}

/// Login credentials.
public struct Credentials: Equatable, Sendable {
    public let username: String
    public let password: String
    public let otpCode: String?

    public init(username: String, password: String, otpCode: String? = nil) {
        self.username = username
        self.password = password
        self.otpCode = otpCode
    }

    /// Creates new credentials with OTP code.
    public func withOTP(_ code: String) -> Credentials {
        Credentials(username: username, password: password, otpCode: code)
    }

    /// Creates new credentials without OTP code.
    public func withoutOTP() -> Credentials {
        Credentials(username: username, password: password, otpCode: nil)
    }
}

/// Login request parameters.
public struct LoginRequest: Equatable, Sendable {
    public let configuration: ServerConfiguration
    public let credentials: Credentials

    public init(configuration: ServerConfiguration, credentials: Credentials) {
        self.configuration = configuration
        self.credentials = credentials
    }
}
