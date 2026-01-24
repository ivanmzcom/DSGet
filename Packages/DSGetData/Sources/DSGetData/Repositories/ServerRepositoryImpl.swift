import Foundation
import DSGetDomain

/// Implementation of ServerRepositoryProtocol.
/// Uses local data source for persistence.
public final class ServerRepositoryImpl: ServerRepositoryProtocol, @unchecked Sendable {

    private let localDataSource: ServerLocalDataSourceProtocol
    private let mapper: ServerMapper

    public init(
        localDataSource: ServerLocalDataSourceProtocol,
        mapper: ServerMapper = ServerMapper()
    ) {
        self.localDataSource = localDataSource
        self.mapper = mapper
    }

    // MARK: - ServerRepositoryProtocol

    public func getServer() async throws -> Server? {
        guard let dto = localDataSource.loadServer() else {
            return nil
        }
        return mapper.toEntity(dto)
    }

    public func saveServer(_ server: Server, credentials: Credentials) async throws {
        let serverDTO = mapper.toDTO(server)
        try localDataSource.saveServer(serverDTO)

        let credentialsDTO = mapper.toCredentialsDTO(serverID: server.id, credentials: credentials)
        try localDataSource.saveCredentials(credentialsDTO)
    }

    public func removeServer() async throws {
        try localDataSource.removeServer()
    }

    public func getCredentials() async throws -> Credentials {
        do {
            let dto = try localDataSource.loadCredentials()
            return mapper.toCredentials(dto)
        } catch {
            throw DomainError.serverCredentialsNotFound(ServerID())
        }
    }

    public func hasServer() async -> Bool {
        localDataSource.hasServer
    }
}
