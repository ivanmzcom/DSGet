import Foundation

/// Domain-specific errors with no framework dependencies.
public enum DomainError: Error, Equatable, Sendable {
    // MARK: - Authentication Errors

    case notAuthenticated
    case invalidCredentials
    case sessionExpired
    case otpRequired
    case otpInvalid
    case reloginFailed

    // MARK: - Network Errors

    case noConnection
    case timeout
    case serverUnreachable
    case invalidServerConfiguration

    // MARK: - API Errors

    case apiError(code: Int, message: String)
    case invalidResponse
    case decodingFailed(String)

    // MARK: - Task Errors

    case taskNotFound(TaskID)
    case taskOperationFailed(TaskID, reason: String)
    case invalidDownloadURL
    case emptyTorrentFile
    case invalidTorrentFileName

    // MARK: - Feed Errors

    case feedNotFound(FeedID)
    case invalidFeedURL
    case feedRefreshFailed(FeedID)

    // MARK: - Server Errors

    case serverNotFound
    case serverCredentialsNotFound(ServerID)
    case noServersConfigured

    // MARK: - File System Errors

    case pathNotFound(String)
    case folderCreationFailed(reason: String)
    case accessDenied(path: String)

    // MARK: - Cache Errors

    case cacheEmpty
    case cacheExpired

    // MARK: - General

    case unknown(String)
}

// MARK: - Error Description

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated."

        case .invalidCredentials:
            return "Invalid username or password."

        case .sessionExpired:
            return "Session has expired. Please log in again."

        case .otpRequired:
            return "OTP code is required for login."

        case .otpInvalid:
            return "Invalid OTP code."

        case .reloginFailed:
            return "Failed to re-authenticate."

        case .noConnection:
            return "No internet connection."

        case .timeout:
            return "Connection timed out."

        case .serverUnreachable:
            return "Unable to reach the server."

        case .invalidServerConfiguration:
            return "Invalid server configuration."

        case let .apiError(code, message):
            return "Server error (\(code)): \(message)"

        case .invalidResponse:
            return "Invalid server response."

        case .decodingFailed(let detail):
            return "Failed to parse response: \(detail)"

        case .taskNotFound(let id):
            return "Task not found: \(id.rawValue)"

        case let .taskOperationFailed(id, reason):
            return "Task operation failed (\(id.rawValue)): \(reason)"

        case .invalidDownloadURL:
            return "Invalid download URL."

        case .emptyTorrentFile:
            return "Torrent file is empty."

        case .invalidTorrentFileName:
            return "Invalid torrent file name."

        case .feedNotFound(let id):
            return "Feed not found: \(id.rawValue)"

        case .invalidFeedURL:
            return "Invalid feed URL."

        case .feedRefreshFailed(let id):
            return "Failed to refresh feed: \(id.rawValue)"

        case .serverNotFound:
            return "Server not found."

        case .serverCredentialsNotFound(let id):
            return "Credentials not found for server: \(id.rawValue.uuidString)"

        case .noServersConfigured:
            return "No servers configured."

        case .pathNotFound(let path):
            return "Path not found: \(path)"

        case .folderCreationFailed(let reason):
            return "Failed to create folder: \(reason)"

        case .accessDenied(let path):
            return "Access denied: \(path)"

        case .cacheEmpty:
            return "No cached data available."

        case .cacheExpired:
            return "Cached data has expired."

        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Error Categories

extension DomainError {
    /// Whether this error requires user to log in again.
    public var requiresRelogin: Bool {
        switch self {
        case .notAuthenticated, .sessionExpired, .invalidCredentials, .reloginFailed:
            return true

        default:
            return false
        }
    }

    /// Whether this error is due to connectivity issues.
    public var isConnectivityError: Bool {
        switch self {
        case .noConnection, .timeout, .serverUnreachable:
            return true

        default:
            return false
        }
    }

    /// Whether cached data can be used as fallback.
    public var canUseCacheFallback: Bool {
        isConnectivityError || self == .timeout
    }

    /// Whether the error is recoverable.
    public var isRecoverable: Bool {
        switch self {
        case .timeout, .serverUnreachable, .sessionExpired, .otpRequired:
            return true

        default:
            return false
        }
    }

    /// User-friendly title for the error.
    public var title: String {
        switch self {
        case .notAuthenticated, .invalidCredentials, .sessionExpired, .otpRequired, .otpInvalid, .reloginFailed:
            return "Authentication Error"

        case .noConnection, .timeout, .serverUnreachable, .invalidServerConfiguration:
            return "Connection Error"

        case .apiError, .invalidResponse, .decodingFailed:
            return "Server Error"

        case .taskNotFound, .taskOperationFailed, .invalidDownloadURL, .emptyTorrentFile, .invalidTorrentFileName:
            return "Task Error"

        case .feedNotFound, .invalidFeedURL, .feedRefreshFailed:
            return "Feed Error"

        case .serverNotFound, .serverCredentialsNotFound, .noServersConfigured:
            return "Server Error"

        case .pathNotFound, .folderCreationFailed, .accessDenied:
            return "File System Error"

        case .cacheEmpty, .cacheExpired:
            return "Cache Error"

        case .unknown:
            return "Error"
        }
    }
}
