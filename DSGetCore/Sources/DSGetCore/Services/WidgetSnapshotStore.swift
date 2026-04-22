import Foundation

public struct WidgetSnapshotStore {
    public static let downloadsKey = "widget_downloads_snapshot"

    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(userDefaults: UserDefaults = DSGetSharedStorage.userDefaults) {
        self.userDefaults = userDefaults
    }

    public func save(_ snapshot: WidgetDownloadsSnapshot) throws {
        let data = try encoder.encode(snapshot)
        userDefaults.set(data, forKey: Self.downloadsKey)
    }

    public func load() -> WidgetDownloadsSnapshot? {
        guard let data = userDefaults.data(forKey: Self.downloadsKey) else {
            return nil
        }
        return try? decoder.decode(WidgetDownloadsSnapshot.self, from: data)
    }

    public func clear() {
        userDefaults.removeObject(forKey: Self.downloadsKey)
    }
}
