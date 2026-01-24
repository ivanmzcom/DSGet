import Foundation

/// Protocol for file station remote data operations.
public protocol FileRemoteDataSource: Sendable {
    // MARK: - Browse Operations

    func fetchShares() async throws -> FileStationShareListDTO
    func fetchFolderContents(path: String) async throws -> FileStationFileListDTO
    func createFolder(parentPath: String, name: String) async throws
}
