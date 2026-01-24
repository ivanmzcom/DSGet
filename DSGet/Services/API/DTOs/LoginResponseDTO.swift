import Foundation

/// Response from SYNO.API.Auth login method.
struct LoginResponseDTO: Decodable {
    let sid: String?
    let isPortalPort: Bool?
    let synotoken: String?

    private enum CodingKeys: String, CodingKey {
        case sid
        case isPortalPort = "is_portal_port"
        case synotoken
    }

    init(sid: String?, isPortalPort: Bool? = nil, synotoken: String? = nil) {
        self.sid = sid
        self.isPortalPort = isPortalPort
        self.synotoken = synotoken
    }
}

/// DTO for storing API configuration in Keychain.
struct APIConfigurationDTO: Codable, Sendable {
    let host: String
    let port: Int
    let username: String
    let password: String
    let useHTTPS: Bool
    var sid: String?

    init(
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
