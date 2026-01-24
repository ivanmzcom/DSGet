import Foundation

/// File Station file entry.
struct FileStationFileDTO: Decodable {
    let name: String
    let path: String
    let isdir: Bool
    let additional: FileStationAdditionalDTO?

    init(name: String, path: String, isdir: Bool, additional: FileStationAdditionalDTO? = nil) {
        self.name = name
        self.path = path
        self.isdir = isdir
        self.additional = additional
    }
}

/// Additional file information.
struct FileStationAdditionalDTO: Decodable {
    let realPath: String?
    let size: Int64?
    let owner: FileStationOwnerDTO?
    let time: FileStationTimeDTO?

    private enum CodingKeys: String, CodingKey {
        case realPath = "real_path"
        case size, owner, time
    }

    init(realPath: String? = nil, size: Int64? = nil, owner: FileStationOwnerDTO? = nil, time: FileStationTimeDTO? = nil) {
        self.realPath = realPath
        self.size = size
        self.owner = owner
        self.time = time
    }
}

/// File owner information.
struct FileStationOwnerDTO: Decodable {
    let user: String?
    let group: String?

    init(user: String? = nil, group: String? = nil) {
        self.user = user
        self.group = group
    }
}

/// File time information.
struct FileStationTimeDTO: Decodable {
    let atime: TimeInterval?
    let mtime: TimeInterval?
    let ctime: TimeInterval?
    let crtime: TimeInterval?

    init(atime: TimeInterval? = nil, mtime: TimeInterval? = nil, ctime: TimeInterval? = nil, crtime: TimeInterval? = nil) {
        self.atime = atime
        self.mtime = mtime
        self.ctime = ctime
        self.crtime = crtime
    }
}

/// Share list response.
struct FileStationShareListDTO: Decodable {
    let shares: [FileStationFileDTO]
    let total: Int
    let offset: Int

    init(shares: [FileStationFileDTO], total: Int, offset: Int) {
        self.shares = shares
        self.total = total
        self.offset = offset
    }
}

/// File list response.
struct FileStationFileListDTO: Decodable {
    let files: [FileStationFileDTO]
    let total: Int
    let offset: Int

    init(files: [FileStationFileDTO], total: Int, offset: Int) {
        self.files = files
        self.total = total
        self.offset = offset
    }
}
