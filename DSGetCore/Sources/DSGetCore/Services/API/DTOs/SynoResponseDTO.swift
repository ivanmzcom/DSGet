import Foundation

/// Generic wrapper for all Synology API responses.
public struct SynoResponseDTO<T: Decodable>: Decodable {
    public let data: T?
    public let success: Bool
    public let error: SynoErrorDTO?

    public init(data: T?, success: Bool, error: SynoErrorDTO? = nil) {
        self.data = data
        self.success = success
        self.error = error
    }
}

/// Represents empty response data for void API operations.
public struct EmptyDataDTO: Decodable {
    public init() {}
}

/// API error information from Synology responses.
public struct SynoErrorDTO: Decodable, Sendable {
    public let code: Int
    public let description: String?

    private enum CodingKeys: String, CodingKey {
        case code
        case description
    }

    public init(from decoder: Decoder) throws {
        if let code = try? decoder.singleValueContainer().decode(Int.self) {
            self.code = code
            description = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(Int.self, forKey: .code)
        description = try container.decodeIfPresent(String.self, forKey: .description)
    }

    public init(code: Int, description: String? = nil) {
        self.code = code
        self.description = description
    }

    /// Known Synology error codes.
    public enum KnownCode: Int {
        case unknown = -1
        case noError = 0
        case serverUnknown = 100
        case invalidParameter = 101
        case apiNotExist = 102
        case methodNotExist = 103
        case versionNotSupported = 104
        case permissionDenied = 105
        case sessionExpired = 106
        case duplicateLogin = 107
        case otpRequired = 403
        case otpInvalid = 404
    }

    /// Whether this error indicates session expiration.
    public var isSessionExpired: Bool {
        code == KnownCode.sessionExpired.rawValue || code == KnownCode.duplicateLogin.rawValue
    }

    /// Whether this error requires OTP.
    public var requiresOTP: Bool {
        code == KnownCode.otpRequired.rawValue
    }

    /// Whether this error indicates invalid OTP.
    public var isOTPInvalid: Bool {
        code == KnownCode.otpInvalid.rawValue
    }
}
