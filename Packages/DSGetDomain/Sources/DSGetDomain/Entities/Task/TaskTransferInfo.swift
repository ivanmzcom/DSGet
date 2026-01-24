import Foundation

/// Transfer statistics for a download task.
public struct TaskTransferInfo: Equatable, Sendable, Hashable {
    public let downloaded: ByteSize
    public let uploaded: ByteSize
    public let downloadSpeed: ByteSize  // per second
    public let uploadSpeed: ByteSize    // per second

    public init(
        downloaded: ByteSize,
        uploaded: ByteSize,
        downloadSpeed: ByteSize,
        uploadSpeed: ByteSize
    ) {
        self.downloaded = downloaded
        self.uploaded = uploaded
        self.downloadSpeed = downloadSpeed
        self.uploadSpeed = uploadSpeed
    }

    /// Progress as a fraction from 0.0 to 1.0.
    public func progress(totalSize: ByteSize) -> Double {
        guard totalSize.bytes > 0 else { return 0 }
        return min(1.0, Double(downloaded.bytes) / Double(totalSize.bytes))
    }

    /// Share ratio (uploaded / downloaded).
    public var shareRatio: Double {
        guard downloaded.bytes > 0 else { return 0 }
        return Double(uploaded.bytes) / Double(downloaded.bytes)
    }

    /// Estimated time remaining based on current download speed.
    public func estimatedTimeRemaining(totalSize: ByteSize) -> TimeInterval? {
        guard downloadSpeed.bytes > 0 else { return nil }
        let remaining = totalSize.bytes - downloaded.bytes
        guard remaining > 0 else { return nil }
        return TimeInterval(remaining) / TimeInterval(downloadSpeed.bytes)
    }

    /// Formatted download speed string.
    public var formattedDownloadSpeed: String {
        "\(downloadSpeed.formatted)/s"
    }

    /// Formatted upload speed string.
    public var formattedUploadSpeed: String {
        "\(uploadSpeed.formatted)/s"
    }

    /// Whether there is active download traffic.
    public var isDownloading: Bool {
        downloadSpeed.bytes > 0
    }

    /// Whether there is active upload traffic.
    public var isUploading: Bool {
        uploadSpeed.bytes > 0
    }

    /// Default empty transfer info.
    public static let empty = TaskTransferInfo(
        downloaded: .zero,
        uploaded: .zero,
        downloadSpeed: .zero,
        uploadSpeed: .zero
    )
}
