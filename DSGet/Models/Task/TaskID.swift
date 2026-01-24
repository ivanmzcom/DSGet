import Foundation

/// Strongly typed identifier for download tasks.
/// Provides type safety to prevent mixing up string identifiers.
struct TaskID: Hashable, Sendable, ExpressibleByStringLiteral, CustomStringConvertible {
    let rawValue: String

    init(_ value: String) {
        self.rawValue = value
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }

    var description: String {
        rawValue
    }

    nonisolated static func == (lhs: TaskID, rhs: TaskID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

extension TaskID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
