import Foundation

/// Value type representing a size in bytes.
/// Provides type safety and convenient conversions for file sizes.
public struct ByteSize: Equatable, Sendable, Comparable, ExpressibleByIntegerLiteral, Hashable {
    public let bytes: Int64

    public init(bytes: Int64) {
        self.bytes = bytes
    }

    public init(integerLiteral value: Int64) {
        self.bytes = value
    }

    // MARK: - Factory Methods

    public static func kilobytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024))
    }

    public static func megabytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024 * 1024))
    }

    public static func gigabytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024 * 1024 * 1024))
    }

    public static func terabytes(_ value: Double) -> ByteSize {
        ByteSize(bytes: Int64(value * 1024 * 1024 * 1024 * 1024))
    }

    // MARK: - Computed Properties

    public var kilobytes: Double {
        Double(bytes) / 1024
    }

    public var megabytes: Double {
        Double(bytes) / (1024 * 1024)
    }

    public var gigabytes: Double {
        Double(bytes) / (1024 * 1024 * 1024)
    }

    public var terabytes: Double {
        Double(bytes) / (1024 * 1024 * 1024 * 1024)
    }

    /// Human-readable formatted string (e.g., "1.5 GB", "500 MB")
    public var formatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Comparable

    public static func < (lhs: ByteSize, rhs: ByteSize) -> Bool {
        lhs.bytes < rhs.bytes
    }

    // MARK: - Arithmetic

    public static func + (lhs: ByteSize, rhs: ByteSize) -> ByteSize {
        ByteSize(bytes: lhs.bytes + rhs.bytes)
    }

    public static func - (lhs: ByteSize, rhs: ByteSize) -> ByteSize {
        ByteSize(bytes: max(0, lhs.bytes - rhs.bytes))
    }

    public static func * (lhs: ByteSize, rhs: Int64) -> ByteSize {
        ByteSize(bytes: lhs.bytes * rhs)
    }

    public static func * (lhs: Int64, rhs: ByteSize) -> ByteSize {
        ByteSize(bytes: lhs * rhs.bytes)
    }

    public static func / (lhs: ByteSize, rhs: Int64) -> ByteSize {
        guard rhs != 0 else { return .zero }
        return ByteSize(bytes: lhs.bytes / rhs)
    }

    // MARK: - Compound Assignment

    public static func += (lhs: inout ByteSize, rhs: ByteSize) {
        lhs = lhs + rhs
    }

    public static func -= (lhs: inout ByteSize, rhs: ByteSize) {
        lhs = lhs - rhs
    }

    // MARK: - Speed Formatting

    /// Formats as speed (per second), e.g., "1.5 MB/s"
    public var formattedAsSpeed: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes) + "/s"
    }

    /// Whether this is effectively zero (useful for checking activity)
    public var isZero: Bool {
        bytes == 0
    }

    /// Ratio to another ByteSize (useful for progress calculations)
    public func ratio(to other: ByteSize) -> Double {
        guard other.bytes > 0 else { return 0 }
        return Double(bytes) / Double(other.bytes)
    }

    // MARK: - Constants

    public static let zero = ByteSize(bytes: 0)
}
