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

    private enum CodingKeys: String, CodingKey {
        case id, title, size, status, type, username, additional
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        title = try container.decodeFlexibleString(forKey: .title)
        size = try container.decodeFlexibleInt64(forKey: .size)
        status = try container.decodeFlexibleString(forKey: .status)
        type = try container.decodeFlexibleString(forKey: .type)
        username = try container.decodeFlexibleString(forKey: .username)
        additional = try container.decodeIfPresent(TaskAdditionalDTO.self, forKey: .additional)
    }

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

    private enum CodingKeys: String, CodingKey {
        case detail, transfer, file, files, tracker, trackers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        detail = try container.decodeIfPresent(TaskDetailDTO.self, forKey: .detail)
        transfer = try container.decodeIfPresent(TaskTransferDTO.self, forKey: .transfer)
        file = try container.decodeIfPresent([TaskFileDTO].self, forKey: .file)
            ?? container.decodeIfPresent([TaskFileDTO].self, forKey: .files)
        tracker = try container.decodeIfPresent([TaskTrackerDTO].self, forKey: .tracker)
            ?? container.decodeIfPresent([TaskTrackerDTO].self, forKey: .trackers)
    }

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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        completedTime = try container.decodeFlexibleTimeIntervalIfPresent(forKey: .completedTime)
        connectedLeechers = try container.decodeFlexibleIntIfPresent(forKey: .connectedLeechers)
        connectedPeers = try container.decodeFlexibleIntIfPresent(forKey: .connectedPeers)
        connectedSeeders = try container.decodeFlexibleIntIfPresent(forKey: .connectedSeeders)
        createTime = try container.decodeFlexibleTimeIntervalIfPresent(forKey: .createTime)
        destination = try container.decodeIfPresent(String.self, forKey: .destination)
        seedelapsed = try container.decodeFlexibleTimeIntervalIfPresent(forKey: .seedelapsed)
        startedTime = try container.decodeFlexibleTimeIntervalIfPresent(forKey: .startedTime)
        totalPeers = try container.decodeFlexibleIntIfPresent(forKey: .totalPeers)
        totalPieces = try container.decodeFlexibleIntIfPresent(forKey: .totalPieces)
        totalSize = try container.decodeFlexibleInt64IfPresent(forKey: .totalSize)
        unzipPassword = try container.decodeIfPresent(String.self, forKey: .unzipPassword)
        uri = try container.decodeIfPresent(String.self, forKey: .uri)
        waitingSeconds = try container.decodeFlexibleIntIfPresent(forKey: .waitingSeconds)
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sizeDownloaded = try container.decodeFlexibleInt64(forKey: .sizeDownloaded)
        sizeUploaded = try container.decodeFlexibleInt64(forKey: .sizeUploaded)
        speedDownload = try container.decodeFlexibleInt(forKey: .speedDownload)
        speedUpload = try container.decodeFlexibleInt(forKey: .speedUpload)
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filename = try container.decodeIfPresent(String.self, forKey: .filename)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        size = try container.decodeFlexibleInt64IfPresent(forKey: .size)
        sizeDownloaded = try container.decodeFlexibleInt64IfPresent(forKey: .sizeDownloaded)
        priority = try container.decodeIfPresent(String.self, forKey: .priority)
        wanted = try container.decodeIfPresent(Bool.self, forKey: .wanted)
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
        case updateTimer = "update_timer"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        updateUrl = try container.decodeIfPresent(String.self, forKey: .updateUrl)
        updateInterval = try container.decodeFlexibleIntIfPresent(forKey: .updateInterval)
            ?? container.decodeFlexibleIntIfPresent(forKey: .updateTimer)
    }
}

/// Result of task action operations.
public struct TaskActionResultDTO: Decodable {
    public let id: String
    public let error: Int

    private enum CodingKeys: String, CodingKey {
        case id, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        error = try container.decodeFlexibleInt(forKey: .error)
    }

    public init(id: String, error: Int) {
        self.id = id
        self.error = error
    }
}

/// Result of task edit operation.
public typealias TaskEditResultDTO = TaskActionResultDTO

private extension KeyedDecodingContainer {
    func decodeFlexibleString(forKey key: Key) throws -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Int64.self, forKey: key) {
            return String(value)
        }
        return try decode(String.self, forKey: key)
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key), let intValue = Int(value) {
            return intValue
        }
        return try decode(Int.self, forKey: key)
    }

    func decodeFlexibleIntIfPresent(forKey key: Key) throws -> Int? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) {
            return nil
        }
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key), let intValue = Int(value) {
            return intValue
        }
        return try decodeIfPresent(Int.self, forKey: key)
    }

    func decodeFlexibleInt64(forKey key: Key) throws -> Int64 {
        if let value = try? decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key), let intValue = Int64(value) {
            return intValue
        }
        return try decode(Int64.self, forKey: key)
    }

    func decodeFlexibleInt64IfPresent(forKey key: Key) throws -> Int64? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) {
            return nil
        }
        if let value = try? decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key), let intValue = Int64(value) {
            return intValue
        }
        return try decodeIfPresent(Int64.self, forKey: key)
    }

    func decodeFlexibleTimeIntervalIfPresent(forKey key: Key) throws -> TimeInterval? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) {
            return nil
        }
        if let value = try? decode(TimeInterval.self, forKey: key) {
            return value
        }
        if let value = try? decode(String.self, forKey: key), let doubleValue = TimeInterval(value) {
            return doubleValue
        }
        return try decodeIfPresent(TimeInterval.self, forKey: key)
    }
}
