import Foundation

/// Value type representing a size in bytes.
/// Provides type safety and convenient conversions for file sizes.
struct ByteSize: Equatable, Sendable, Comparable, ExpressibleByIntegerLiteral, Hashable {
    let bytes: Int64

    init(bytes: Int64) {
        self.bytes = bytes
    }

    init(integerLiteral value: Int64) {
        self.bytes = value
    }

    // MARK: - Factory Methods

    static func kilobytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024))
    }

    static func megabytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024 * 1024))
    }

    static func gigabytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024 * 1024 * 1024))
    }

    static func terabytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024 * 1024 * 1024 * 1024))
    }

    // MARK: - Computed Properties

    var kilobytes: Double {
        Double(bytes) / 1024
    }

    var megabytes: Double {
        Double(bytes) / (1024 * 1024)
    }

    var gigabytes: Double {
        Double(bytes) / (1024 * 1024 * 1024)
    }

    var terabytes: Double {
        Double(bytes) / (1024 * 1024 * 1024 * 1024)
    }

    /// Human-readable formatted string (e.g., "1.5 GB", "500 MB")
    var formatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Comparable

    static func < (lhs: ByteSize, rhs: ByteSize) -> Bool {
        lhs.bytes < rhs.bytes
    }

    // MARK: - Arithmetic

    static func + (lhs: ByteSize, rhs: ByteSize) -> ByteSize {
        ByteSize(bytes: lhs.bytes + rhs.bytes)
    }

    static func - (lhs: ByteSize, rhs: ByteSize) -> ByteSize {
        ByteSize(bytes: max(0, lhs.bytes - rhs.bytes))
    }

    static func * (lhs: ByteSize, rhs: Int64) -> ByteSize {
        ByteSize(bytes: lhs.bytes * rhs)
    }

    static func * (lhs: Int64, rhs: ByteSize) -> ByteSize {
        ByteSize(bytes: lhs * rhs.bytes)
    }

    static func / (lhs: ByteSize, rhs: Int64) -> ByteSize {
        guard rhs != 0 else { return .zero }
        return ByteSize(bytes: lhs.bytes / rhs)
    }

    // MARK: - Compound Assignment

    static func += (lhs: inout ByteSize, rhs: ByteSize) {
        lhs = lhs + rhs
    }

    static func -= (lhs: inout ByteSize, rhs: ByteSize) {
        lhs = lhs - rhs
    }

    // MARK: - Speed Formatting

    /// Formats as speed (per second), e.g., "1.5 MB/s"
    var formattedAsSpeed: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes) + "/s"
    }

    /// Whether this is effectively zero (useful for checking activity)
    var isZero: Bool {
        bytes == 0
    }

    /// Ratio to another ByteSize (useful for progress calculations)
    func ratio(to other: ByteSize) -> Double {
        guard other.bytes > 0 else { return 0 }
        return Double(bytes) / Double(other.bytes)
    }

    // MARK: - Constants

    static let zero = ByteSize(bytes: 0)
}
