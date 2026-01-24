import Foundation

/// Strongly typed identifier for RSS feeds.
struct FeedID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    let rawValue: String

    init(_ value: String) {
        self.rawValue = value
    }

    init(_ value: Int) {
        self.rawValue = String(value)
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }

    var description: String {
        rawValue
    }

    /// Numeric ID for API calls that require Int.
    var numericValue: Int? {
        Int(rawValue)
    }

    nonisolated static func == (lhs: FeedID, rhs: FeedID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension FeedID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self.rawValue = String(intValue)
        } else {
            self.rawValue = try container.decode(String.self)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
