import SwiftUI

enum AppSection: String, Hashable, CaseIterable {
    case downloads
    case feeds
    case settings

    static var availableSections: [AppSection] {
        #if os(macOS)
        [.downloads, .feeds]
        #else
        allCases
        #endif
    }

    var label: String {
        switch self {
        case .downloads: return String.localized("tab.downloads")
        case .feeds: return String.localized("tab.feeds")
        case .settings: return String.localized("tab.settings")
        }
    }

    var icon: String {
        switch self {
        case .downloads: return "arrow.down.circle"
        case .feeds: return "dot.radiowaves.left.and.right"
        case .settings: return "gear"
        }
    }
}
