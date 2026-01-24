import Foundation
@testable import DSGetDomain

// MARK: - Mock Server Repository

final class MockServerRepository: ServerRepositoryProtocol, @unchecked Sendable {
    var server: Server?
    var credentials: Credentials?
    var getServerCallCount = 0
    var saveServerCallCount = 0
    var removeServerCallCount = 0
    var getCredentialsCallCount = 0
    var errorToThrow: Error?

    func getServer() async throws -> Server? {
        getServerCallCount += 1
        if let error = errorToThrow { throw error }
        return server
    }

    func saveServer(_ server: Server, credentials: Credentials) async throws {
        saveServerCallCount += 1
        if let error = errorToThrow { throw error }
        self.server = server
        self.credentials = credentials
    }

    func removeServer() async throws {
        removeServerCallCount += 1
        if let error = errorToThrow { throw error }
        server = nil
        credentials = nil
    }

    func getCredentials() async throws -> Credentials {
        getCredentialsCallCount += 1
        if let error = errorToThrow { throw error }
        guard let credentials = credentials else {
            throw DomainError.serverCredentialsNotFound(ServerID())
        }
        return credentials
    }

    func hasServer() async -> Bool {
        server != nil
    }
}
