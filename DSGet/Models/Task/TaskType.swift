import Foundation

/// Type of download task.
enum TaskType: Equatable, Sendable, Hashable {
    case bt       // BitTorrent
    case nzb      // Usenet
    case http     // HTTP/HTTPS download
    case ftp      // FTP download
    case emule    // eMule/eDonkey
    case unknown(String)

    /// Creates a task type from API string value.
    init(apiValue: String) {
        switch apiValue.lowercased() {
        case "bt": self = .bt
        case "nzb": self = .nzb
        case "http", "https": self = .http
        case "ftp": self = .ftp
        case "emule", "ed2k": self = .emule
        default: self = .unknown(apiValue)
        }
    }

    /// API string value for this type.
    var apiValue: String {
        switch self {
        case .bt: return "bt"
        case .emule: return "emule"
        case .http: return "http"
        case .ftp: return "ftp"
        case .nzb: return "nzb"
        case .unknown(let value): return value
        }
    }

    /// API value for filtering (optional).
    var apiFilterValue: String? {
        switch self {
        case .bt: return "bt"
        case .emule: return "emule"
        case .http: return "http"
        case .ftp: return "ftp"
        case .nzb: return "nzb"
        case .unknown: return nil
        }
    }

    /// Human-readable display name.
    var displayName: String {
        switch self {
        case .bt: return "BitTorrent"
        case .nzb: return "NZB"
        case .http: return "HTTP"
        case .ftp: return "FTP"
        case .emule: return "eMule"
        case .unknown(let value): return value.uppercased()
        }
    }

    /// Icon name for this task type.
    var iconName: String {
        switch self {
        case .bt: return "arrow.down.circle"
        case .nzb: return "newspaper"
        case .http: return "globe"
        case .ftp: return "folder"
        case .emule: return "network"
        case .unknown: return "questionmark.circle"
        }
    }
}
