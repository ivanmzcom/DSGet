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

    public init(code: Int, description: String? = nil) {
        self.code = code
        self.description = description
    }

    /// Known Synology error codes.
    public enum KnownCode: Int {
        case unknown = -1
        case noError = 0
        case invalidParameter = 100
        case apiNotExist = 101
        case methodNotExist = 102
        case versionNotSupported = 103
        case permissionDenied = 104
        case sessionExpired = 105
        case duplicateLogin = 106
        case otpRequired = 403
        case otpInvalid = 404
    }

    /// Whether this error indicates session expiration.
    public var isSessionExpired: Bool {
        code == KnownCode.sessionExpired.rawValue
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
