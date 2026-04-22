import Foundation

/// Authentication context synchronized from the iPhone app to the watch app.
public struct WatchAuthenticationContext: Codable, Sendable {
    public let isAuthenticated: Bool
    public let syncedAt: Date

    public init(
        isAuthenticated: Bool,
        syncedAt: Date = Date()
    ) {
        self.isAuthenticated = isAuthenticated
        self.syncedAt = syncedAt
    }

    public static var authenticated: Self {
        Self(isAuthenticated: true)
    }

    public static var loggedOut: Self {
        Self(isAuthenticated: false)
    }
}
