import Foundation

/// Strongly typed identifier for RSS feeds.
public struct FeedID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    public let rawValue: String

    public init(_ value: String) {
        self.rawValue = value
    }

    public init(_ value: Int) {
        self.rawValue = String(value)
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public var description: String {
        rawValue
    }

    /// Numeric ID for API calls that require Int.
    public var numericValue: Int? {
        Int(rawValue)
    }

    nonisolated public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension FeedID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self.rawValue = String(intValue)
        } else {
            self.rawValue = try container.decode(String.self)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
