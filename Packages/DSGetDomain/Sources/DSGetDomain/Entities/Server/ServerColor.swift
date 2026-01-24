import Foundation

/// Color options for server identification.
/// Allows users to visually distinguish between multiple servers.
public enum ServerColor: String, CaseIterable, Sendable, Codable, Hashable {
    case blue
    case green
    case orange
    case purple
    case red
    case teal
    case pink
    case indigo

    /// Display name for the color.
    public var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .green: return "Green"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .red: return "Red"
        case .teal: return "Teal"
        case .pink: return "Pink"
        case .indigo: return "Indigo"
        }
    }

    /// Default color for new servers.
    public static var `default`: ServerColor {
        .blue
    }
}

#if canImport(SwiftUI)
import SwiftUI

extension ServerColor {
    /// SwiftUI Color representation.
    public var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .red: return .red
        case .teal: return .teal
        case .pink: return .pink
        case .indigo: return .indigo
        }
    }
}
#endif
