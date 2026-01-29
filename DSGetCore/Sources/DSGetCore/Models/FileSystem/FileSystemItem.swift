import Foundation

/// A file or folder in the file system.
public struct FileSystemItem: Equatable, Sendable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let size: ByteSize?
    public let modificationDate: Date?
    public let owner: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        isDirectory: Bool,
        size: ByteSize? = nil,
        modificationDate: Date? = nil,
        owner: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.modificationDate = modificationDate
        self.owner = owner
    }

    /// Whether this is a file (not a directory).
    public var isFile: Bool {
        !isDirectory
    }

    /// File extension (lowercase), empty for directories.
    public var fileExtension: String {
        guard isFile else { return "" }
        return (name as NSString).pathExtension.lowercased()
    }

    /// Parent path.
    public var parentPath: String {
        (path as NSString).deletingLastPathComponent
    }

    /// Full path including name.
    public var fullPath: String {
        if path.hasSuffix("/") {
            return path + name
        }
        return path + "/" + name
    }

    /// Icon name based on type.
    public var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        switch fileExtension {
        case "torrent":
            return "arrow.down.circle.fill"

        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"

        case "mp4", "mkv", "avi", "mov":
            return "film"

        case "mp3", "flac", "aac", "wav":
            return "music.note"

        case "jpg", "jpeg", "png", "gif":
            return "photo"

        case "pdf":
            return "doc.fill"

        default:
            return "doc"
        }
    }
}

// MARK: - Preview

extension FileSystemItem {
    public static func previewFolder(name: String = "Downloads") -> FileSystemItem {
        FileSystemItem(
            name: name,
            path: "/volume1",
            isDirectory: true
        )
    }

    public static func previewFile(name: String = "movie.mkv") -> FileSystemItem {
        FileSystemItem(
            name: name,
            path: "/volume1/Downloads",
            isDirectory: false,
            size: .gigabytes(4.5),
            modificationDate: Date()
        )
    }
}
