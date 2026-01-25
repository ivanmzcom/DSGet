import Foundation

/// Status of a download task.
public enum TaskStatus: Equatable, Sendable, Hashable {
    case waiting
    case downloading
    case paused
    case finishing
    case finished
    case hashChecking
    case seeding
    case filehostingWaiting
    case extracting
    case error
    case unknown(String)

    /// Creates a status from API string value.
    public init(apiValue: String) {
        switch apiValue.lowercased() {
        case "waiting": self = .waiting
        case "downloading": self = .downloading
        case "paused": self = .paused
        case "finishing": self = .finishing
        case "finished": self = .finished
        case "hash_checking": self = .hashChecking
        case "seeding": self = .seeding
        case "filehosting_waiting": self = .filehostingWaiting
        case "extracting": self = .extracting
        case "error": self = .error
        default: self = .unknown(apiValue)
        }
    }

    /// API string value for this status.
    public var apiValue: String {
        switch self {
        case .waiting: return "waiting"
        case .downloading: return "downloading"
        case .paused: return "paused"
        case .finishing: return "finishing"
        case .finished: return "finished"
        case .hashChecking: return "hash_checking"
        case .seeding: return "seeding"
        case .filehostingWaiting: return "filehosting_waiting"
        case .extracting: return "extracting"
        case .error: return "error"
        case .unknown(let value): return value
        }
    }

    /// Whether the task is actively transferring data.
    public var isActive: Bool {
        switch self {
        case .downloading, .seeding, .finishing, .extracting:
            return true
        default:
            return false
        }
    }

    /// Whether the task can be paused.
    public var canPause: Bool {
        switch self {
        case .downloading, .waiting, .seeding:
            return true
        default:
            return false
        }
    }

    /// Whether the task can be resumed.
    public var canResume: Bool {
        self == .paused
    }

    /// Whether the task is considered complete.
    public var isCompleted: Bool {
        switch self {
        case .finished, .seeding:
            return true
        default:
            return false
        }
    }

    /// Whether the task has an error.
    public var hasError: Bool {
        self == .error
    }

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .waiting: return "Waiting"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .finishing: return "Finishing"
        case .finished: return "Finished"
        case .hashChecking: return "Checking"
        case .seeding: return "Seeding"
        case .filehostingWaiting: return "Waiting"
        case .extracting: return "Extracting"
        case .error: return "Error"
        case .unknown(let value): return value.capitalized
        }
    }
}
