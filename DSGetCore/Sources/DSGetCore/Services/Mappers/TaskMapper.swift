import Foundation

/// Maps between Task DTOs and Domain Entities.
public struct TaskMapper: Sendable {
    public init() {}

    // MARK: - DTO to Entity

    /// Maps a DownloadTaskDTO to a DownloadTask entity.
    public func mapToEntity(_ dto: DownloadTaskDTO) -> DownloadTask {
        let transfer = dto.additional?.transfer.map { mapTransfer($0) }
        return DownloadTask(
            id: TaskID(dto.id),
            title: dto.title,
            size: ByteSize(bytes: dto.size),
            status: TaskStatus(apiValue: dto.status),
            type: TaskType(apiValue: dto.type),
            username: dto.username,
            detail: dto.additional?.detail.map { mapDetail($0) },
            transfer: transfer,
            files: mapFiles(dto, transfer: transfer),
            trackers: dto.additional?.tracker?.map { mapTracker($0) } ?? []
        )
    }

    /// Maps a list of DownloadTaskDTOs to entities.
    public func mapToEntities(_ dtos: [DownloadTaskDTO]) -> [DownloadTask] {
        dtos.map { mapToEntity($0) }
    }

    // MARK: - Private Mapping Methods

    private func mapDetail(_ dto: TaskDetailDTO) -> TaskDetail {
        TaskDetail(
            destination: dto.destination ?? "",
            uri: dto.uri,
            createTime: dto.createTime.map { Date(timeIntervalSince1970: $0) },
            startedTime: dto.startedTime.map { Date(timeIntervalSince1970: $0) },
            completedTime: dto.completedTime.map { Date(timeIntervalSince1970: $0) },
            totalSize: dto.totalSize.map { ByteSize(bytes: $0) },
            totalPieces: dto.totalPieces,
            connectedSeeders: dto.connectedSeeders ?? 0,
            connectedLeechers: dto.connectedLeechers ?? 0,
            connectedPeers: dto.connectedPeers ?? 0,
            totalPeers: dto.totalPeers ?? 0,
            seedElapsed: dto.seedelapsed,
            waitingSeconds: dto.waitingSeconds,
            unzipPassword: dto.unzipPassword
        )
    }

    private func mapTransfer(_ dto: TaskTransferDTO) -> TaskTransferInfo {
        TaskTransferInfo(
            downloaded: ByteSize(bytes: dto.sizeDownloaded),
            uploaded: ByteSize(bytes: dto.sizeUploaded),
            downloadSpeed: ByteSize(bytes: Int64(dto.speedDownload)),
            uploadSpeed: ByteSize(bytes: Int64(dto.speedUpload))
        )
    }

    private func mapFile(_ dto: TaskFileDTO) -> TaskFile {
        TaskFile(
            name: dto.filename ?? dto.name ?? "",
            size: ByteSize(bytes: dto.size ?? 0),
            downloadedSize: ByteSize(bytes: dto.sizeDownloaded ?? 0),
            priority: FilePriority(apiValue: dto.priority),
            isWanted: dto.wanted ?? true
        )
    }

    private func mapFiles(_ dto: DownloadTaskDTO, transfer: TaskTransferInfo?) -> [TaskFile] {
        let files = dto.additional?.file?.map { mapFile($0) } ?? []
        if !files.isEmpty {
            return files
        }

        let title = dto.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, dto.size > 0 else { return [] }

        let status = TaskStatus(apiValue: dto.status)
        let downloadedSize = transfer?.downloaded ?? (status.isCompleted ? ByteSize(bytes: dto.size) : .zero)
        return [
            TaskFile(
                id: dto.id,
                name: title,
                size: ByteSize(bytes: dto.size),
                downloadedSize: downloadedSize
            )
        ]
    }

    private func mapTracker(_ dto: TaskTrackerDTO) -> TaskTracker {
        TaskTracker(
            url: dto.url ?? dto.updateUrl ?? "",
            status: TrackerStatus(apiValue: dto.status),
            updateInterval: dto.updateInterval
        )
    }
}
