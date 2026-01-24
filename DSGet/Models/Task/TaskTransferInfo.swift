import Foundation

/// Transfer statistics for a download task.
struct TaskTransferInfo: Equatable, Sendable, Hashable {
    let downloaded: ByteSize
    let uploaded: ByteSize
    let downloadSpeed: ByteSize  // per second
    let uploadSpeed: ByteSize    // per second

    init(
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
    func progress(totalSize: ByteSize) -> Double {
        guard totalSize.bytes > 0 else { return 0 }
        return min(1.0, Double(downloaded.bytes) / Double(totalSize.bytes))
    }

    /// Share ratio (uploaded / downloaded).
    var shareRatio: Double {
        guard downloaded.bytes > 0 else { return 0 }
        return Double(uploaded.bytes) / Double(downloaded.bytes)
    }

    /// Estimated time remaining based on current download speed.
    func estimatedTimeRemaining(totalSize: ByteSize) -> TimeInterval? {
        guard downloadSpeed.bytes > 0 else { return nil }
        let remaining = totalSize.bytes - downloaded.bytes
        guard remaining > 0 else { return nil }
        return TimeInterval(remaining) / TimeInterval(downloadSpeed.bytes)
    }

    /// Formatted download speed string.
    var formattedDownloadSpeed: String {
        "\(downloadSpeed.formatted)/s"
    }

    /// Formatted upload speed string.
    var formattedUploadSpeed: String {
        "\(uploadSpeed.formatted)/s"
    }

    /// Whether there is active download traffic.
    var isDownloading: Bool {
        downloadSpeed.bytes > 0
    }

    /// Whether there is active upload traffic.
    var isUploading: Bool {
        uploadSpeed.bytes > 0
    }

    /// Default empty transfer info.
    static let empty = TaskTransferInfo(
        downloaded: .zero,
        uploaded: .zero,
        downloadSpeed: .zero,
        uploadSpeed: .zero
    )
}
