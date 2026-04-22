import Foundation

public enum WidgetDownloadStatus: String, Codable, Sendable {
    case downloading
    case paused
    case completed
    case failed
    case pending

    public var isActive: Bool {
        self == .downloading
    }

    public var isCompleted: Bool {
        self == .completed
    }

    public var isFailed: Bool {
        self == .failed
    }
}

public struct WidgetDownloadItem: Codable, Identifiable, Sendable {
    public let id: String
    public let fileName: String
    public let progress: Double
    public let status: WidgetDownloadStatus
    public let totalBytes: Int64
    public let downloadedBytes: Int64
    public let downloadSpeedBytes: Int64
    public let uploadSpeedBytes: Int64

    public init(
        id: String,
        fileName: String,
        progress: Double,
        status: WidgetDownloadStatus,
        totalBytes: Int64,
        downloadedBytes: Int64,
        downloadSpeedBytes: Int64 = 0,
        uploadSpeedBytes: Int64 = 0
    ) {
        self.id = id
        self.fileName = fileName
        self.progress = progress
        self.status = status
        self.totalBytes = totalBytes
        self.downloadedBytes = downloadedBytes
        self.downloadSpeedBytes = downloadSpeedBytes
        self.uploadSpeedBytes = uploadSpeedBytes
    }
}

public struct WidgetDownloadsSnapshot: Codable, Sendable {
    public let items: [WidgetDownloadItem]
    public let mainItemID: String?
    public let isConnected: Bool
    public let updatedAt: Date

    public init(
        items: [WidgetDownloadItem],
        mainItemID: String?,
        isConnected: Bool,
        updatedAt: Date = Date()
    ) {
        self.items = items
        self.mainItemID = mainItemID
        self.isConnected = isConnected
        self.updatedAt = updatedAt
    }

    public var mainItem: WidgetDownloadItem? {
        guard let mainItemID else { return items.first }
        return items.first(where: { $0.id == mainItemID }) ?? items.first
    }

    public var activeCount: Int {
        items.filter(\.status.isActive).count
    }

    public var completedCount: Int {
        items.filter(\.status.isCompleted).count
    }

    public var failedCount: Int {
        items.filter(\.status.isFailed).count
    }
}
