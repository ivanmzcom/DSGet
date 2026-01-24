import Foundation
import DSGetDomain

/// Implementation of FileSystemRepositoryProtocol.
public final class FileSystemRepositoryImpl: FileSystemRepositoryProtocol, @unchecked Sendable {

    private let remoteDataSource: FileRemoteDataSource
    private let mapper: FileMapper

    public init(
        remoteDataSource: FileRemoteDataSource,
        mapper: FileMapper = FileMapper()
    ) {
        self.remoteDataSource = remoteDataSource
        self.mapper = mapper
    }

    // MARK: - Browse Operations

    public func getShares() async throws -> [FileSystemItem] {
        let dto = try await remoteDataSource.fetchShares()
        return mapper.mapToEntities(dto.shares)
    }

    public func getFolderContents(path: String) async throws -> [FileSystemItem] {
        let dto = try await remoteDataSource.fetchFolderContents(path: path)
        return mapper.mapToEntities(dto.files)
    }

    public func createFolder(parentPath: String, name: String) async throws {
        try await remoteDataSource.createFolder(parentPath: parentPath, name: name)
    }
}
