import Foundation
import DSGetDomain

/// Maps between Auth DTOs and Domain Entities.
public struct AuthMapper {

    public init() {}

    // MARK: - DTO to Entity

    /// Maps a LoginResponseDTO to a Session entity.
    public func mapToSession(_ dto: LoginResponseDTO, serverConfig: ServerConfiguration) -> Session {
        Session(
            sessionID: dto.sid ?? "",
            serverConfiguration: serverConfig,
            createdAt: Date()
        )
    }

    /// Creates a Session from stored APIConfigurationDTO.
    public func mapToSession(from config: APIConfigurationDTO) -> Session? {
        guard let sessionID = config.sid, !sessionID.isEmpty else { return nil }

        let serverConfig = ServerConfiguration(
            host: config.host,
            port: config.port,
            useHTTPS: config.useHTTPS
        )

        return Session(
            sessionID: sessionID,
            serverConfiguration: serverConfig,
            createdAt: Date()
        )
    }

    /// Creates ServerConfiguration from APIConfigurationDTO.
    public func mapToServerConfiguration(from config: APIConfigurationDTO) -> ServerConfiguration {
        ServerConfiguration(
            host: config.host,
            port: config.port,
            useHTTPS: config.useHTTPS
        )
    }

    // MARK: - Entity to DTO

    /// Maps ServerConfiguration and credentials to APIConfigurationDTO for storage.
    public func mapToStorageDTO(
        _ config: ServerConfiguration,
        username: String,
        password: String,
        sessionID: String?
    ) -> APIConfigurationDTO {
        APIConfigurationDTO(
            host: config.host,
            port: config.port,
            username: username,
            password: password,
            useHTTPS: config.useHTTPS,
            sid: sessionID
        )
    }
}
