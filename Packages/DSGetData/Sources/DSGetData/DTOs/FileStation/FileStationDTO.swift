import Foundation

/// File Station file entry.
public struct FileStationFileDTO: Decodable {
    public let name: String
    public let path: String
    public let isdir: Bool
    public let additional: FileStationAdditionalDTO?

    public init(name: String, path: String, isdir: Bool, additional: FileStationAdditionalDTO? = nil) {
        self.name = name
        self.path = path
        self.isdir = isdir
        self.additional = additional
    }
}

/// Additional file information.
public struct FileStationAdditionalDTO: Decodable {
    public let realPath: String?
    public let size: Int64?
    public let owner: FileStationOwnerDTO?
    public let time: FileStationTimeDTO?

    private enum CodingKeys: String, CodingKey {
        case realPath = "real_path"
        case size, owner, time
    }

    public init(realPath: String? = nil, size: Int64? = nil, owner: FileStationOwnerDTO? = nil, time: FileStationTimeDTO? = nil) {
        self.realPath = realPath
        self.size = size
        self.owner = owner
        self.time = time
    }
}

/// File owner information.
public struct FileStationOwnerDTO: Decodable {
    public let user: String?
    public let group: String?

    public init(user: String? = nil, group: String? = nil) {
        self.user = user
        self.group = group
    }
}

/// File time information.
public struct FileStationTimeDTO: Decodable {
    public let atime: TimeInterval?
    public let mtime: TimeInterval?
    public let ctime: TimeInterval?
    public let crtime: TimeInterval?

    public init(atime: TimeInterval? = nil, mtime: TimeInterval? = nil, ctime: TimeInterval? = nil, crtime: TimeInterval? = nil) {
        self.atime = atime
        self.mtime = mtime
        self.ctime = ctime
        self.crtime = crtime
    }
}

/// Share list response.
public struct FileStationShareListDTO: Decodable {
    public let shares: [FileStationFileDTO]
    public let total: Int
    public let offset: Int

    public init(shares: [FileStationFileDTO], total: Int, offset: Int) {
        self.shares = shares
        self.total = total
        self.offset = offset
    }
}

/// File list response.
public struct FileStationFileListDTO: Decodable {
    public let files: [FileStationFileDTO]
    public let total: Int
    public let offset: Int

    public init(files: [FileStationFileDTO], total: Int, offset: Int) {
        self.files = files
        self.total = total
        self.offset = offset
    }
}
