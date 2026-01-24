import Foundation

/// Network-level errors.
enum NetworkError: Error, LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case timeout
    case noConnection
    case sslError(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .timeout:
            return "Request timed out"
        case .noConnection:
            return "No internet connection"
        case .sslError(let message):
            return "SSL error: \(message)"
        case .cancelled:
            return "Request was cancelled"
        }
    }

    /// Creates NetworkError from URLError.
    static func from(_ urlError: URLError) -> NetworkError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noConnection
        case .timedOut:
            return .timeout
        case .cancelled:
            return .cancelled
        case .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            return .sslError(urlError.localizedDescription)
        default:
            return .httpError(statusCode: urlError.errorCode)
        }
    }
}
