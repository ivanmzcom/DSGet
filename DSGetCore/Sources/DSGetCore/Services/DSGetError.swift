//
//  DSGetError.swift
//  DSGetCore
//

import Foundation

// MARK: - DSGetError

public enum DSGetError: Error, LocalizedError {
    case network(NetworkErrorType)
    case api(APIErrorType)
    case authentication(AuthError)
    case validation(ValidationError)

    // MARK: - Network Errors

    public enum NetworkErrorType: Sendable {
        case offline
        case timeout
        case requestFailed(reason: String)

        public var localizedDescription: String {
            switch self {
            case .offline:
                return "No Internet connection."

            case .timeout:
                return "Connection timed out."

            case .requestFailed(let reason):
                return "Network error: \(reason)"
            }
        }
    }

    // MARK: - API Errors

    public enum APIErrorType: Sendable {
        case sessionExpired
        case invalidResponse
        case serverError(code: Int, message: String)
        case otpRequired

        public var localizedDescription: String {
            switch self {
            case .sessionExpired:
                return "Session expired. Please log in again."

            case .invalidResponse:
                return "Invalid server response."

            case let .serverError(code, message):
                return "Server error (\(code)): \(message)"

            case .otpRequired:
                return "OTP code required."
            }
        }
    }

    // MARK: - Authentication Errors

    public enum AuthError: Sendable {
        case notLoggedIn
        case invalidCredentials

        public var localizedDescription: String {
            switch self {
            case .notLoggedIn:
                return "Not logged in."

            case .invalidCredentials:
                return "Invalid username or password."
            }
        }
    }

    // MARK: - Validation Errors

    public enum ValidationError: Sendable {
        case emptyURL
        case invalidURL
        case noDownloadURL

        public var localizedDescription: String {
            switch self {
            case .emptyURL:
                return "URL cannot be empty."

            case .invalidURL:
                return "Invalid URL."

            case .noDownloadURL:
                return "This item doesn't have a download link available."
            }
        }
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .api(let error): return error.localizedDescription
        case .authentication(let error): return error.localizedDescription
        case .validation(let error): return error.localizedDescription
        }
    }

    // MARK: - Authentication Check

    /// Whether this error requires the user to log in again.
    public var requiresRelogin: Bool {
        switch self {
        case .authentication:
            return true

        case .api(.sessionExpired):
            return true

        default:
            return false
        }
    }

    // MARK: - Conversion

    public static func from(_ error: Error) -> Self {
        if let urlError = error as? URLError {
            return fromURLError(urlError)
        }
        if let keychainError = error as? KeychainError {
            return fromKeychainError(keychainError)
        }
        if let dataError = error as? DataError {
            return fromDataError(dataError)
        }
        if let dsgetError = error as? Self {
            return dsgetError
        }
        return fromUnknownError(error)
    }

    private static func fromURLError(_ error: URLError) -> Self {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .network(.offline)

        case .timedOut:
            return .network(.timeout)

        default:
            return .network(.requestFailed(reason: error.localizedDescription))
        }
    }

    private static func fromKeychainError(_ error: KeychainError) -> Self {
        if case .itemNotFound = error {
            return .authentication(.notLoggedIn)
        }
        return .network(.requestFailed(reason: error.localizedDescription))
    }

    private static func fromDataError(_ error: DataError) -> Self {
        switch error {
        case .notAuthenticated:
            return .authentication(.notLoggedIn)

        case .sessionExpired:
            return .api(.sessionExpired)

        case .decodingFailed(let underlyingError):
            return .api(.serverError(code: -1, message: "Decoding failed: \(underlyingError.localizedDescription)"))

        case .networkError(let netError):
            switch netError {
            case .timeout:
                return .network(.timeout)

            case .noConnection:
                return .network(.offline)

            default:
                return .network(.requestFailed(reason: netError.localizedDescription))
            }

        case .apiError(let synoError):
            return .api(.serverError(code: synoError.code, message: synoError.description ?? "Unknown server error"))

        case .cacheExpired, .cacheMiss:
            return .network(.requestFailed(reason: error.localizedDescription))

        case .keychainError:
            return .authentication(.notLoggedIn)

        case .validationError(let message):
            return .network(.requestFailed(reason: message))

        case .otpRequired:
            return .api(.otpRequired)

        case .otpInvalid:
            return .authentication(.invalidCredentials)

        case .notFound(let message):
            return .api(.serverError(code: 404, message: message))

        case .invalidResponse:
            return .api(.invalidResponse)
        }
    }

    private static func fromUnknownError(_ error: Error) -> Self {
        let errorTypeName = String(describing: type(of: error))
        if errorTypeName == "NetworkError" {
            let description = error.localizedDescription
            if description.contains("cancelled") {
                return .network(.requestFailed(reason: "Request was cancelled"))
            } else if description.contains("connection") || description.contains("offline") {
                return .network(.offline)
            } else if description.contains("timed out") {
                return .network(.timeout)
            }
            return .network(.requestFailed(reason: description))
        }
        return .api(.serverError(code: -1, message: error.localizedDescription))
    }
}
