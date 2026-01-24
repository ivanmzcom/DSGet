import Foundation

/// Generic wrapper for all Synology API responses.
struct SynoResponseDTO<T: Decodable>: Decodable {
    let data: T?
    let success: Bool
    let error: SynoErrorDTO?

    init(data: T?, success: Bool, error: SynoErrorDTO? = nil) {
        self.data = data
        self.success = success
        self.error = error
    }
}

/// Represents empty response data for void API operations.
struct EmptyDataDTO: Decodable {
    init() {}
}

/// API error information from Synology responses.
struct SynoErrorDTO: Decodable, Sendable {
    let code: Int
    let description: String?

    init(code: Int, description: String? = nil) {
        self.code = code
        self.description = description
    }

    /// Known Synology error codes.
    enum KnownCode: Int {
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
    var isSessionExpired: Bool {
        code == KnownCode.sessionExpired.rawValue
    }

    /// Whether this error requires OTP.
    var requiresOTP: Bool {
        code == KnownCode.otpRequired.rawValue
    }

    /// Whether this error indicates invalid OTP.
    var isOTPInvalid: Bool {
        code == KnownCode.otpInvalid.rawValue
    }
}
