import Foundation

/// Detailed information about a download task.
public struct TaskDetail: Equatable, Sendable, Hashable {
    public let destination: String
    public let uri: String?
    public let createTime: Date?
    public let startedTime: Date?
    public let completedTime: Date?
    public let totalSize: ByteSize?
    public let totalPieces: Int?
    public let connectedSeeders: Int
    public let connectedLeechers: Int
    public let connectedPeers: Int
    public let totalPeers: Int
    public let seedElapsed: TimeInterval?
    public let waitingSeconds: Int?
    public let unzipPassword: String?

    public init(
        destination: String = "",
        uri: String? = nil,
        createTime: Date? = nil,
        startedTime: Date? = nil,
        completedTime: Date? = nil,
        totalSize: ByteSize? = nil,
        totalPieces: Int? = nil,
        connectedSeeders: Int = 0,
        connectedLeechers: Int = 0,
        connectedPeers: Int = 0,
        totalPeers: Int = 0,
        seedElapsed: TimeInterval? = nil,
        waitingSeconds: Int? = nil,
        unzipPassword: String? = nil
    ) {
        self.destination = destination
        self.uri = uri
        self.createTime = createTime
        self.startedTime = startedTime
        self.completedTime = completedTime
        self.totalSize = totalSize
        self.totalPieces = totalPieces
        self.connectedSeeders = connectedSeeders
        self.connectedLeechers = connectedLeechers
        self.connectedPeers = connectedPeers
        self.totalPeers = totalPeers
        self.seedElapsed = seedElapsed
        self.waitingSeconds = waitingSeconds
        self.unzipPassword = unzipPassword
    }

    /// Duration from start to completion.
    public var downloadDuration: TimeInterval? {
        guard let start = startedTime, let end = completedTime else { return nil }
        return end.timeIntervalSince(start)
    }

    /// Time elapsed since task was created.
    public var ageFromCreation: TimeInterval? {
        guard let created = createTime else { return nil }
        return Date().timeIntervalSince(created)
    }

    /// Whether the task has peer information (typically BitTorrent).
    public var hasPeerInfo: Bool {
        connectedSeeders > 0 || connectedLeechers > 0 || connectedPeers > 0 || totalPeers > 0
    }

    /// Formatted peer information string.
    public var peerInfoString: String {
        if hasPeerInfo {
            return "S:\(connectedSeeders)/\(totalPeers) L:\(connectedLeechers) P:\(connectedPeers)"
        }
        return ""
    }

    /// Default empty detail.
    public static let empty = TaskDetail()
}
