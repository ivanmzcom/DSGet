import Foundation
import DSGetDomain

/// Maps between Server DTOs and Domain entities.
public struct ServerMapper: Sendable {

    public init() {}

    // MARK: - DTO to Entity

    public func toEntity(_ dto: ServerDTO) -> Server {
        Server(
            id: ServerID(dto.id),
            name: dto.name,
            configuration: ServerConfiguration(
                host: dto.host,
                port: dto.port,
                useHTTPS: dto.useHTTPS
            ),
            iconColor: ServerColor(rawValue: dto.iconColor) ?? .default,
            createdAt: dto.createdAt,
            lastConnectedAt: dto.lastConnectedAt
        )
    }

    // MARK: - Entity to DTO

    public func toDTO(_ entity: Server) -> ServerDTO {
        ServerDTO(
            id: entity.id.rawValue,
            name: entity.name,
            host: entity.configuration.host,
            port: entity.configuration.port,
            useHTTPS: entity.configuration.useHTTPS,
            iconColor: entity.iconColor.rawValue,
            createdAt: entity.createdAt,
            lastConnectedAt: entity.lastConnectedAt
        )
    }

    // MARK: - Credentials

    public func toCredentialsDTO(serverID: ServerID, credentials: Credentials) -> ServerCredentialsDTO {
        ServerCredentialsDTO(
            serverID: serverID.rawValue,
            username: credentials.username,
            password: credentials.password
        )
    }

    public func toCredentials(_ dto: ServerCredentialsDTO) -> Credentials {
        Credentials(
            username: dto.username,
            password: dto.password
        )
    }
}
