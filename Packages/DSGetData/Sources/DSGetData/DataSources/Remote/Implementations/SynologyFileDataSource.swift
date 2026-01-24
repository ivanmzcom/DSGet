import Foundation

/// Synology API implementation for FileStation operations.
public final class SynologyFileDataSource: FileRemoteDataSource, @unchecked Sendable {

    private let apiClient: SynologyAPIClient

    public init(apiClient: SynologyAPIClient) {
        self.apiClient = apiClient
    }

    public func fetchShares() async throws -> FileStationShareListDTO {
        let response: SynoResponseDTO<FileStationShareListDTO> = try await apiClient.get(
            endpoint: .fileStation,
            api: "SYNO.FileStation.List",
            method: "list_share",
            version: 2
        )

        guard let data = response.data else {
            return FileStationShareListDTO(shares: [], total: 0, offset: 0)
        }

        return data
    }

    public func fetchFolderContents(path: String) async throws -> FileStationFileListDTO {
        let response: SynoResponseDTO<FileStationFileListDTO> = try await apiClient.get(
            endpoint: .fileStation,
            api: "SYNO.FileStation.List",
            method: "list",
            version: 2,
            params: [
                "folder_path": path,
                "filetype": "all",
                "additional": "[\"real_path\",\"size\",\"time\"]"
            ]
        )

        guard let data = response.data else {
            return FileStationFileListDTO(files: [], total: 0, offset: 0)
        }

        return data
    }

    public func createFolder(parentPath: String, name: String) async throws {
        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .fileStation,
            api: "SYNO.FileStation.CreateFolder",
            method: "create",
            version: 2,
            params: [
                "folder_path": parentPath,
                "name": name
            ]
        )
    }
}
