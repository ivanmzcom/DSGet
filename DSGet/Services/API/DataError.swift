import Foundation

/// Errors that can occur in the Data layer.
enum DataError: Error, LocalizedError, Sendable {
    case notAuthenticated
    case sessionExpired
    case decodingFailed(Error)
    case networkError(NetworkError)
    case apiError(SynoErrorDTO)
    case cacheExpired
    case cacheMiss
    case keychainError(Error)
    case validationError(String)
    case otpRequired
    case otpInvalid
    case notFound(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .sessionExpired:
            return "Session has expired"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return error.localizedDescription
        case .apiError(let error):
            return "API error \(error.code): \(error.description ?? "Unknown")"
        case .cacheExpired:
            return "Cache has expired"
        case .cacheMiss:
            return "No cached data available"
        case .keychainError(let error):
            return "Keychain error: \(error.localizedDescription)"
        case .validationError(let message):
            return message
        case .otpRequired:
            return "OTP code is required"
        case .otpInvalid:
            return "Invalid OTP code"
        case .notFound(let message):
            return message
        case .invalidResponse:
            return "Invalid or empty response from server"
        }
    }
}
