import Foundation

/// Response wrapper for task list endpoint.
struct TaskListResponseDTO: Decodable {
    let tasks: [DownloadTaskDTO]
    let total: Int?
    let offset: Int?

    init(tasks: [DownloadTaskDTO], total: Int? = nil, offset: Int? = nil) {
        self.tasks = tasks
        self.total = total
        self.offset = offset
    }
}

/// Individual download task from SYNO.DownloadStation.Task API.
struct DownloadTaskDTO: Decodable {
    let id: String
    let title: String
    let size: Int64
    let status: String
    let type: String
    let username: String
    let additional: TaskAdditionalDTO?

    init(
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
struct TaskAdditionalDTO: Decodable {
    let detail: TaskDetailDTO?
    let transfer: TaskTransferDTO?
    let file: [TaskFileDTO]?
    let tracker: [TaskTrackerDTO]?

    init(
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
struct TaskDetailDTO: Decodable {
    let completedTime: TimeInterval?
    let connectedLeechers: Int?
    let connectedPeers: Int?
    let connectedSeeders: Int?
    let createTime: TimeInterval?
    let destination: String?
    let seedelapsed: TimeInterval?
    let startedTime: TimeInterval?
    let totalPeers: Int?
    let totalPieces: Int?
    let totalSize: Int64?
    let unzipPassword: String?
    let uri: String?
    let waitingSeconds: Int?

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
struct TaskTransferDTO: Decodable {
    let sizeDownloaded: Int64
    let sizeUploaded: Int64
    let speedDownload: Int
    let speedUpload: Int

    private enum CodingKeys: String, CodingKey {
        case sizeDownloaded = "size_downloaded"
        case sizeUploaded = "size_uploaded"
        case speedDownload = "speed_download"
        case speedUpload = "speed_upload"
    }

    init(
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
struct TaskFileDTO: Decodable {
    let filename: String?
    let name: String?
    let size: Int64?
    let sizeDownloaded: Int64?
    let priority: String?
    let wanted: Bool?

    private enum CodingKeys: String, CodingKey {
        case filename, name, size
        case sizeDownloaded = "size_downloaded"
        case priority, wanted
    }
}

/// Task tracker information.
struct TaskTrackerDTO: Decodable {
    let url: String?
    let status: String?
    let updateUrl: String?
    let updateInterval: Int?

    private enum CodingKeys: String, CodingKey {
        case url, status
        case updateUrl = "update_url"
        case updateInterval = "update_interval"
    }
}

/// Result of task edit operation.
struct TaskEditResultDTO: Decodable {
    let id: String
    let error: Int

    init(id: String, error: Int) {
        self.id = id
        self.error = error
    }
}
