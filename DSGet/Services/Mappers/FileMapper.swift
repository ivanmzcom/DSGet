import Foundation

/// Maps between FileStation DTOs and Domain Entities.
struct FileMapper {

    init() {}

    // MARK: - File DTO to Entity

    /// Maps a FileStationFileDTO to a FileSystemItem entity.
    func mapToEntity(_ dto: FileStationFileDTO) -> FileSystemItem {
        FileSystemItem(
            name: dto.name,
            path: dto.path,
            isDirectory: dto.isdir,
            size: dto.additional?.size.map { ByteSize(bytes: $0) },
            modificationDate: dto.additional?.time?.mtime.map { Date(timeIntervalSince1970: $0) },
            owner: dto.additional?.owner?.user
        )
    }

    /// Maps a list of FileStationFileDTOs to entities.
    func mapToEntities(_ dtos: [FileStationFileDTO]) -> [FileSystemItem] {
        dtos.map { mapToEntity($0) }
    }
}
