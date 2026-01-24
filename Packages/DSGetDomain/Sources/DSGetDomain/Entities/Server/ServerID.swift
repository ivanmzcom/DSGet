import Foundation

/// Strongly typed identifier for servers.
/// Uses UUID for locally generated identifiers.
public struct ServerID: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID

    public init(_ value: UUID = UUID()) {
        self.rawValue = value
    }

    public init?(uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString) else { return nil }
        self.rawValue = uuid
    }

    public var description: String {
        rawValue.uuidString
    }

    public var uuidString: String {
        rawValue.uuidString
    }
}

extension ServerID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(UUID.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ServerID: Equatable {
    public static func == (lhs: ServerID, rhs: ServerID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
