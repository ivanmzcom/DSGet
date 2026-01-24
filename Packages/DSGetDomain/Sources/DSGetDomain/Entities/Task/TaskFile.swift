import Foundation

/// A file within a torrent/download task.
public struct TaskFile: Equatable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let size: ByteSize
    public let downloadedSize: ByteSize
    public let priority: FilePriority
    public let isWanted: Bool

    public init(
        id: String = UUID().uuidString,
        name: String,
        size: ByteSize,
        downloadedSize: ByteSize = .zero,
        priority: FilePriority = .normal,
        isWanted: Bool = true
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.downloadedSize = downloadedSize
        self.priority = priority
        self.isWanted = isWanted
    }

    /// Download progress as a fraction from 0.0 to 1.0.
    public var progress: Double {
        guard size.bytes > 0 else { return 0 }
        return min(1.0, Double(downloadedSize.bytes) / Double(size.bytes))
    }

    /// Whether the file download is complete.
    public var isComplete: Bool {
        downloadedSize >= size && size.bytes > 0
    }

    /// File extension (lowercase).
    public var fileExtension: String {
        (name as NSString).pathExtension.lowercased()
    }

    /// File name without extension.
    public var nameWithoutExtension: String {
        (name as NSString).deletingPathExtension
    }
}

/// Priority level for file downloads.
public enum FilePriority: Equatable, Sendable, Hashable {
    case skip
    case low
    case normal
    case high

    public init(apiValue: String?) {
        switch apiValue?.lowercased() {
        case "skip": self = .skip
        case "low": self = .low
        case "high": self = .high
        default: self = .normal
        }
    }

    public var apiValue: String {
        switch self {
        case .skip: return "skip"
        case .low: return "low"
        case .normal: return "normal"
        case .high: return "high"
        }
    }

    public var displayName: String {
        switch self {
        case .skip: return "Skip"
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        }
    }
}
