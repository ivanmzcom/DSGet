import Foundation

/// Pure domain entity representing a download task.
/// Immutable value type with no framework dependencies.
public struct DownloadTask: Equatable, Sendable, Identifiable, Hashable {
    public let id: TaskID
    public let title: String
    public let size: ByteSize
    public let status: TaskStatus
    public let type: TaskType
    public let username: String
    public let detail: TaskDetail?
    public let transfer: TaskTransferInfo?
    public let files: [TaskFile]
    public let trackers: [TaskTracker]

    public init(
        id: TaskID,
        title: String,
        size: ByteSize,
        status: TaskStatus,
        type: TaskType,
        username: String,
        detail: TaskDetail? = nil,
        transfer: TaskTransferInfo? = nil,
        files: [TaskFile] = [],
        trackers: [TaskTracker] = []
    ) {
        self.id = id
        self.title = title
        self.size = size
        self.status = status
        self.type = type
        self.username = username
        self.detail = detail
        self.transfer = transfer
        self.files = files
        self.trackers = trackers
    }

    // MARK: - Computed Properties

    /// Download progress as a fraction from 0.0 to 1.0.
    public var progress: Double {
        guard let transfer = transfer, size.bytes > 0 else { return 0 }
        return transfer.progress(totalSize: size)
    }

    /// Whether the task is actively downloading.
    public var isDownloading: Bool {
        status == .downloading
    }

    /// Whether the task is paused.
    public var isPaused: Bool {
        status == .paused
    }

    /// Whether the task is completed (finished or seeding).
    public var isCompleted: Bool {
        status.isCompleted
    }

    /// Whether the task has an error.
    public var hasError: Bool {
        status.hasError
    }

    /// Destination folder path.
    public var destination: String {
        detail?.destination ?? ""
    }

    /// Current download speed.
    public var downloadSpeed: ByteSize {
        transfer?.downloadSpeed ?? .zero
    }

    /// Current upload speed.
    public var uploadSpeed: ByteSize {
        transfer?.uploadSpeed ?? .zero
    }

    /// Downloaded size so far.
    public var downloadedSize: ByteSize {
        transfer?.downloaded ?? .zero
    }

    /// Uploaded size so far.
    public var uploadedSize: ByteSize {
        transfer?.uploaded ?? .zero
    }

    /// Share ratio.
    public var shareRatio: Double {
        transfer?.shareRatio ?? 0
    }

    /// Number of connected seeders.
    public var seeders: Int {
        detail?.connectedSeeders ?? 0
    }

    /// Number of connected leechers.
    public var leechers: Int {
        detail?.connectedLeechers ?? 0
    }

    /// Number of connected peers.
    public var peers: Int {
        detail?.connectedPeers ?? 0
    }

    /// Creation date of the task.
    public var createdAt: Date? {
        detail?.createTime
    }

    /// Completion date of the task.
    public var completedAt: Date? {
        detail?.completedTime
    }

    /// Date used for sorting (completedTime if available, otherwise createTime).
    public var sortDate: Date? {
        detail?.completedTime ?? detail?.createTime
    }

    /// Estimated time remaining for download.
    public var estimatedTimeRemaining: TimeInterval? {
        transfer?.estimatedTimeRemaining(totalSize: size)
    }

    /// Number of files in the task.
    public var fileCount: Int {
        files.count
    }

    /// Whether the task is a BitTorrent download.
    public var isTorrent: Bool {
        type == .bt
    }
}

// MARK: - Convenience Initializers

extension DownloadTask {
    /// Creates a minimal task for testing or previews.
    public static func preview(
        id: String = "preview-task",
        title: String = "Sample Task",
        status: TaskStatus = .downloading,
        progress: Double = 0.5
    ) -> DownloadTask {
        let size = ByteSize.gigabytes(1)
        let downloaded = ByteSize(bytes: Int64(Double(size.bytes) * progress))

        return DownloadTask(
            id: TaskID(id),
            title: title,
            size: size,
            status: status,
            type: .bt,
            username: "admin",
            detail: TaskDetail(destination: "/downloads"),
            transfer: TaskTransferInfo(
                downloaded: downloaded,
                uploaded: .zero,
                downloadSpeed: .megabytes(5),
                uploadSpeed: .megabytes(1)
            )
        )
    }
}
