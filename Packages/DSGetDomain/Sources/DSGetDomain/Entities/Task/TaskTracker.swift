import Foundation

/// A tracker for a BitTorrent task.
public struct TaskTracker: Equatable, Sendable, Identifiable, Hashable {
    public let id: String
    public let url: String
    public let status: TrackerStatus
    public let updateInterval: Int?

    public init(
        id: String = UUID().uuidString,
        url: String,
        status: TrackerStatus,
        updateInterval: Int? = nil
    ) {
        self.id = id
        self.url = url
        self.status = status
        self.updateInterval = updateInterval
    }

    /// Extracts the hostname from the tracker URL.
    public var hostname: String? {
        URL(string: url)?.host
    }

    /// Whether the tracker is currently working.
    public var isWorking: Bool {
        status == .success || status == .updating
    }
}

/// Status of a tracker connection.
public enum TrackerStatus: Equatable, Sendable, Hashable {
    case updating
    case success
    case failed
    case disabled
    case unknown(String)

    public init(apiValue: String?) {
        switch apiValue?.lowercased() {
        case "updating": self = .updating
        case "success": self = .success
        case "failed", "error": self = .failed
        case "disabled": self = .disabled
        default: self = .unknown(apiValue ?? "")
        }
    }

    public var displayName: String {
        switch self {
        case .updating: return "Updating"
        case .success: return "OK"
        case .failed: return "Failed"
        case .disabled: return "Disabled"
        case .unknown(let value): return value.capitalized
        }
    }

    public var iconName: String {
        switch self {
        case .updating: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .disabled: return "pause.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}
