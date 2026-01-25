import Foundation

/// Response wrapper for task list endpoint.
public struct TaskListResponseDTO: Decodable {
    public let tasks: [DownloadTaskDTO]
    public let total: Int?
    public let offset: Int?

    public init(tasks: [DownloadTaskDTO], total: Int? = nil, offset: Int? = nil) {
        self.tasks = tasks
        self.total = total
        self.offset = offset
    }
}

/// Individual download task from SYNO.DownloadStation.Task API.
public struct DownloadTaskDTO: Decodable {
    public let id: String
    public let title: String
    public let size: Int64
    public let status: String
    public let type: String
    public let username: String
    public let additional: TaskAdditionalDTO?

    public init(
        id: String,
        title: String,
        size: Int64,
        status: String,
        type: String,
        username: String,
        additional: TaskAdditionalDTO? = nil
    ) {
        self.id = id
        self.title = title
        self.size = size
        self.status = status
        self.type = type
        self.username = username
        self.additional = additional
    }
}

/// Additional task information when requested.
public struct TaskAdditionalDTO: Decodable {
    public let detail: TaskDetailDTO?
    public let transfer: TaskTransferDTO?
    public let file: [TaskFileDTO]?
    public let tracker: [TaskTrackerDTO]?

    public init(
        detail: TaskDetailDTO? = nil,
        transfer: TaskTransferDTO? = nil,
        file: [TaskFileDTO]? = nil,
        tracker: [TaskTrackerDTO]? = nil
    ) {
        self.detail = detail
        self.transfer = transfer
        self.file = file
        self.tracker = tracker
    }
}

/// Task detail information.
public struct TaskDetailDTO: Decodable {
    public let completedTime: TimeInterval?
    public let connectedLeechers: Int?
    public let connectedPeers: Int?
    public let connectedSeeders: Int?
    public let createTime: TimeInterval?
    public let destination: String?
    public let seedelapsed: TimeInterval?
    public let startedTime: TimeInterval?
    public let totalPeers: Int?
    public let totalPieces: Int?
    public let totalSize: Int64?
    public let unzipPassword: String?
    public let uri: String?
    public let waitingSeconds: Int?

    private enum CodingKeys: String, CodingKey {
        case completedTime = "completed_time"
        case connectedLeechers = "connected_leechers"
        case connectedPeers = "connected_peers"
        case connectedSeeders = "connected_seeders"
        case createTime = "create_time"
        case destination
        case seedelapsed
        case startedTime = "started_time"
        case totalPeers = "total_peers"
        case totalPieces = "total_pieces"
        case totalSize = "total_size"
        case unzipPassword = "unzip_password"
        case uri
        case waitingSeconds = "waiting_seconds"
    }
}

/// Task transfer statistics.
public struct TaskTransferDTO: Decodable {
    public let sizeDownloaded: Int64
    public let sizeUploaded: Int64
    public let speedDownload: Int
    public let speedUpload: Int

    private enum CodingKeys: String, CodingKey {
        case sizeDownloaded = "size_downloaded"
        case sizeUploaded = "size_uploaded"
        case speedDownload = "speed_download"
        case speedUpload = "speed_upload"
    }

    public init(
        sizeDownloaded: Int64,
        sizeUploaded: Int64,
        speedDownload: Int,
        speedUpload: Int
    ) {
        self.sizeDownloaded = sizeDownloaded
        self.sizeUploaded = sizeUploaded
        self.speedDownload = speedDownload
        self.speedUpload = speedUpload
    }
}

/// Task file information.
public struct TaskFileDTO: Decodable {
    public let filename: String?
    public let name: String?
    public let size: Int64?
    public let sizeDownloaded: Int64?
    public let priority: String?
    public let wanted: Bool?

    private enum CodingKeys: String, CodingKey {
        case filename, name, size
        case sizeDownloaded = "size_downloaded"
        case priority, wanted
    }
}

/// Task tracker information.
public struct TaskTrackerDTO: Decodable {
    public let url: String?
    public let status: String?
    public let updateUrl: String?
    public let updateInterval: Int?

    private enum CodingKeys: String, CodingKey {
        case url, status
        case updateUrl = "update_url"
        case updateInterval = "update_interval"
    }
}

/// Result of task edit operation.
public struct TaskEditResultDTO: Decodable {
    public let id: String
    public let error: Int

    public init(id: String, error: Int) {
        self.id = id
        self.error = error
    }
}
