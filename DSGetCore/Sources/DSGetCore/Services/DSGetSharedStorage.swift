import Foundation

public enum DSGetSharedStorage {
    public static let appGroupIdentifier = "group.es.ncrd.DSGet"
    public static let keychainAccessGroupSuffix = "com.ivanmz.DSGet.shared"

    public static var userDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
