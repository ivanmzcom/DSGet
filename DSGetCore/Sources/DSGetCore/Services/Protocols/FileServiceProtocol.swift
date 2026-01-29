import Foundation

/// Protocol for file system operations.
public protocol FileServiceProtocol: Sendable {
    /// Lists shared folders on the NAS.
    /// - Returns: Array of shared folder items.
    func getShares() async throws -> [FileSystemItem]

    /// Lists contents of a folder.
    /// - Parameter path: The folder path to list.
    /// - Returns: Array of items in the folder.
    func getFolderContents(path: String) async throws -> [FileSystemItem]

    /// Creates a new folder.
    /// - Parameters:
    ///   - parentPath: The parent folder path.
    ///   - name: The name of the new folder.
    func createFolder(parentPath: String, name: String) async throws
}
