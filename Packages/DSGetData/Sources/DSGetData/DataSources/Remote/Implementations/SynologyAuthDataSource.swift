import Foundation

/// Synology API implementation for authentication operations.
public final class SynologyAuthDataSource: AuthRemoteDataSource, @unchecked Sendable {

    private let networkClient: NetworkClientProtocol
    private let decoder: JSONDecoder

    public init(networkClient: NetworkClientProtocol = NetworkClient.shared) {
        self.networkClient = networkClient
        self.decoder = JSONDecoder()
    }

    public func login(
        baseURL: URL,
        username: String,
        password: String,
        otpCode: String?
    ) async throws -> LoginResponseDTO {
        let authURL = baseURL.appendingPathComponent("/webapi/auth.cgi")

        var queryItems = [
            URLQueryItem(name: "api", value: "SYNO.API.Auth"),
            URLQueryItem(name: "method", value: "login"),
            URLQueryItem(name: "version", value: "6"),
            URLQueryItem(name: "account", value: username),
            URLQueryItem(name: "passwd", value: password),
            URLQueryItem(name: "session", value: "DownloadStation"),
            URLQueryItem(name: "format", value: "sid")
        ]

        if let otp = otpCode {
            queryItems.append(URLQueryItem(name: "otp_code", value: otp))
        }

        let (data, _) = try await networkClient.get(url: authURL, queryItems: queryItems)

        let response = try decodeResponse(data, as: LoginResponseDTO.self)

        guard let loginData = response.data else {
            if let error = response.error {
                if error.code == 403 {
                    throw DataError.otpRequired
                } else if error.code == 404 {
                    throw DataError.otpInvalid
                }
                throw DataError.apiError(error)
            }
            throw DataError.validationError("Login failed with no data")
        }

        return loginData
    }

    public func logout(baseURL: URL, sessionID: String) async throws {
        let authURL = baseURL.appendingPathComponent("/webapi/auth.cgi")

        let queryItems = [
            URLQueryItem(name: "api", value: "SYNO.API.Auth"),
            URLQueryItem(name: "method", value: "logout"),
            URLQueryItem(name: "version", value: "1"),
            URLQueryItem(name: "_sid", value: sessionID),
            URLQueryItem(name: "session", value: "DownloadStation")
        ]

        let (data, _) = try await networkClient.get(url: authURL, queryItems: queryItems)
        let _: SynoResponseDTO<EmptyDataDTO> = try decodeResponse(data, as: EmptyDataDTO.self)
    }

    // MARK: - Private Methods

    private func decodeResponse<T: Decodable>(_ data: Data, as type: T.Type) throws -> SynoResponseDTO<T> {
        do {
            let response = try decoder.decode(SynoResponseDTO<T>.self, from: data)
            if !response.success, let error = response.error {
                throw DataError.apiError(error)
            }
            return response
        } catch let error as DataError {
            throw error
        } catch {
            throw DataError.decodingFailed(error)
        }
    }
}
