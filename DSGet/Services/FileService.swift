import Foundation

/// File service implementation for FileStation operations.
final class FileService: FileServiceProtocol, @unchecked Sendable {

    private let apiClient: SynologyAPIClient
    private let mapper: FileMapper

    init(
        apiClient: SynologyAPIClient,
        mapper: FileMapper = FileMapper()
    ) {
        self.apiClient = apiClient
        self.mapper = mapper
    }

    // MARK: - FileServiceProtocol

    func getShares() async throws -> [FileSystemItem] {
        let response: SynoResponseDTO<FileStationShareListDTO> = try await apiClient.get(
            endpoint: .fileStation,
            api: "SYNO.FileStation.List",
            method: "list_share",
            version: 2
        )

        let dto = response.data ?? FileStationShareListDTO(shares: [], total: 0, offset: 0)

        // Map shares to FileSystemItem (shares are treated as directories)
        return dto.shares.map { share in
            FileSystemItem(
                name: share.name,
                path: share.path,
                isDirectory: true,
                size: nil,
                modificationDate: nil,
                owner: nil
            )
        }
    }

    func getFolderContents(path: String) async throws -> [FileSystemItem] {
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

        let dto = response.data ?? FileStationFileListDTO(files: [], total: 0, offset: 0)
        return mapper.mapToEntities(dto.files)
    }

    func createFolder(parentPath: String, name: String) async throws {
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
