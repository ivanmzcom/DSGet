import Foundation

/// Response from SYNO.API.Auth login method.
public struct LoginResponseDTO: Decodable {
    public let sid: String?
    public let isPortalPort: Bool?
    public let synotoken: String?

    private enum CodingKeys: String, CodingKey {
        case sid
        case isPortalPort = "is_portal_port"
        case synotoken
    }

    public init(sid: String?, isPortalPort: Bool? = nil, synotoken: String? = nil) {
        self.sid = sid
        self.isPortalPort = isPortalPort
        self.synotoken = synotoken
    }
}

/// DTO for storing API configuration in Keychain.
public struct APIConfigurationDTO: Codable, Sendable {
    public let host: String
    public let port: Int
    public let username: String
    public let password: String
    public let useHTTPS: Bool
    public var sid: String?

    public init(
        host: String,
        port: Int,
        username: String,
        password: String,
        useHTTPS: Bool,
        sid: String? = nil
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.useHTTPS = useHTTPS
        self.sid = sid
    }
}
