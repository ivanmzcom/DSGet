import Foundation

/// Strongly typed identifier for servers.
/// Uses UUID for locally generated identifiers.
struct ServerID: Hashable, Sendable, CustomStringConvertible {
    let rawValue: UUID

    init(_ value: UUID = UUID()) {
        self.rawValue = value
    }

    init?(uuidString: String) {
        guard let uuid = UUID(uuidString: uuidString) else { return nil }
        self.rawValue = uuid
    }

    var description: String {
        rawValue.uuidString
    }

    var uuidString: String {
        rawValue.uuidString
    }
}

extension ServerID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.rawValue = try container.decode(UUID.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

extension ServerID: Equatable {
    static func == (lhs: ServerID, rhs: ServerID) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}
