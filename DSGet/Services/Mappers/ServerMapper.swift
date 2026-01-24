import Foundation

/// Maps between Server DTOs and Domain entities.
struct ServerMapper: Sendable {

    init() {}

    // MARK: - DTO to Entity

    func toEntity(_ dto: ServerDTO) -> Server {
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

    func toDTO(_ entity: Server) -> ServerDTO {
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

    func toCredentialsDTO(serverID: ServerID, credentials: Credentials) -> ServerCredentialsDTO {
        ServerCredentialsDTO(
            serverID: serverID.rawValue,
            username: credentials.username,
            password: credentials.password
        )
    }

    func toCredentials(_ dto: ServerCredentialsDTO) -> Credentials {
        Credentials(
            username: dto.username,
            password: dto.password
        )
    }
}
