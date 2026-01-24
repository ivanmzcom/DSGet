import Foundation

/// A file or folder in the file system.
struct FileSystemItem: Equatable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    let isDirectory: Bool
    let size: ByteSize?
    let modificationDate: Date?
    let owner: String?

    init(
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
    var isFile: Bool {
        !isDirectory
    }

    /// File extension (lowercase), empty for directories.
    var fileExtension: String {
        guard isFile else { return "" }
        return (name as NSString).pathExtension.lowercased()
    }

    /// Parent path.
    var parentPath: String {
        (path as NSString).deletingLastPathComponent
    }

    /// Full path including name.
    var fullPath: String {
        if path.hasSuffix("/") {
            return path + name
        }
        return path + "/" + name
    }

    /// Icon name based on type.
    var iconName: String {
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
    static func previewFolder(name: String = "Downloads") -> FileSystemItem {
        FileSystemItem(
            name: name,
            path: "/volume1",
            isDirectory: true
        )
    }

    static func previewFile(name: String = "movie.mkv") -> FileSystemItem {
        FileSystemItem(
            name: name,
            path: "/volume1/Downloads",
            isDirectory: false,
            size: .gigabytes(4.5),
            modificationDate: Date()
        )
    }
}
