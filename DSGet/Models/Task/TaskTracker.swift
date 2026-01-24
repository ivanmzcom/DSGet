import Foundation

/// A tracker for a BitTorrent task.
struct TaskTracker: Equatable, Sendable, Identifiable, Hashable {
    let id: String
    let url: String
    let status: TrackerStatus
    let updateInterval: Int?

    init(
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
    var hostname: String? {
        URL(string: url)?.host
    }

    /// Whether the tracker is currently working.
    var isWorking: Bool {
        status == .success || status == .updating
    }
}

/// Status of a tracker connection.
enum TrackerStatus: Equatable, Sendable, Hashable {
    case updating
    case success
    case failed
    case disabled
    case unknown(String)

    init(apiValue: String?) {
        switch apiValue?.lowercased() {
        case "updating": self = .updating
        case "success": self = .success
        case "failed", "error": self = .failed
        case "disabled": self = .disabled
        default: self = .unknown(apiValue ?? "")
        }
    }

    var displayName: String {
        switch self {
        case .updating: return "Updating"
        case .success: return "OK"
        case .failed: return "Failed"
        case .disabled: return "Disabled"
        case .unknown(let value): return value.capitalized
        }
    }

    var iconName: String {
        switch self {
        case .updating: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .disabled: return "pause.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}
