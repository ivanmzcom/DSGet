import Foundation

/// Generic wrapper for all Synology API responses.
/// Mirrors the exact JSON structure returned by Synology APIs.
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
