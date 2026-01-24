import Foundation
import DSGetDomain

/// Maps between Data Layer errors and Domain errors.
public struct ErrorMapper {

    public init() {}

    /// Maps a SynoErrorDTO to a DomainError.
    public func mapAPIError(_ dto: SynoErrorDTO) -> DomainError {
        switch dto.code {
        case SynoErrorDTO.KnownCode.sessionExpired.rawValue:
            return .sessionExpired
        case SynoErrorDTO.KnownCode.permissionDenied.rawValue:
            return .notAuthenticated
        case SynoErrorDTO.KnownCode.invalidParameter.rawValue:
            return .apiError(code: dto.code, message: dto.description ?? "Invalid parameter")
        case SynoErrorDTO.KnownCode.apiNotExist.rawValue,
             SynoErrorDTO.KnownCode.methodNotExist.rawValue:
            return .apiError(code: dto.code, message: dto.description ?? "Operation not supported")
        case SynoErrorDTO.KnownCode.otpRequired.rawValue:
            return .otpRequired
        case SynoErrorDTO.KnownCode.otpInvalid.rawValue:
            return .otpInvalid
        default:
            return .apiError(code: dto.code, message: dto.description ?? "Unknown error")
        }
    }

    /// Maps a NetworkError to a DomainError.
    public func mapNetworkError(_ error: NetworkError) -> DomainError {
        switch error {
        case .noConnection:
            return .noConnection
        case .timeout:
            return .timeout
        case .invalidURL:
            return .invalidDownloadURL
        case .invalidResponse:
            return .invalidResponse
        case .httpError(let statusCode):
            return .apiError(code: statusCode, message: "HTTP error")
        case .sslError(let message):
            return .serverUnreachable
        case .cancelled:
            return .unknown("Request cancelled")
        }
    }

    /// Maps a DataError to a DomainError.
    public func mapDataError(_ error: DataError) -> DomainError {
        switch error {
        case .notAuthenticated:
            return .notAuthenticated
        case .sessionExpired:
            return .sessionExpired
        case .decodingFailed(let underlying):
            return .decodingFailed(underlying.localizedDescription)
        case .networkError(let networkError):
            return mapNetworkError(networkError)
        case .apiError(let synoError):
            return mapAPIError(synoError)
        case .cacheExpired:
            return .cacheExpired
        case .cacheMiss:
            return .cacheEmpty
        case .keychainError(let underlying):
            return .unknown("Keychain error: \(underlying.localizedDescription)")
        case .validationError(let message):
            return .unknown(message)
        case .otpRequired:
            return .otpRequired
        case .otpInvalid:
            return .otpInvalid
        case .notFound(let message):
            return .unknown(message)
        case .invalidResponse:
            return .invalidResponse
        }
    }

    /// Maps any Error to a DomainError.
    public func mapError(_ error: Error) -> DomainError {
        if let dataError = error as? DataError {
            return mapDataError(dataError)
        }
        if let networkError = error as? NetworkError {
            return mapNetworkError(networkError)
        }
        if let domainError = error as? DomainError {
            return domainError
        }
        return .unknown(error.localizedDescription)
    }
}
