import SwiftUI

struct MainSidebarView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @Binding var selectedSection: AppSection?

    var body: some View {
        List(selection: $selectedSection) {
            ForEach(AppSection.availableSections, id: \.self) { section in
                SidebarRow(
                    title: section.label,
                    detail: detailText(for: section),
                    systemImage: section.icon
                )
                    .tag(section)
                    .accessibilityIdentifier(accessibilityIdentifier(for: section))
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("DSGet")
        #if os(macOS)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SettingsLink {
                    Label(String.localized("tab.settings"), systemImage: "gearshape")
                }
            }
        }
        #endif
    }

    private func accessibilityIdentifier(for section: AppSection) -> String {
        switch section {
        case .downloads:
            AccessibilityID.Sidebar.downloads
        case .feeds:
            AccessibilityID.Sidebar.feeds
        case .settings:
            AccessibilityID.Sidebar.settings
        }
    }

    private func detailText(for section: AppSection) -> String? {
        switch section {
        case .downloads:
            let count = appViewModel.tasksViewModel.activeDownloadCount
            return count > 0
                ? String.localized("sidebar.downloads.active", count)
                : String.localized("sidebar.downloads.all")
        case .feeds:
            let favoriteCount = appViewModel.feedsViewModel.favoriteFeedIDs.count
            return favoriteCount > 0
                ? String.localized("sidebar.feeds.favorites", favoriteCount)
                : String.localized("sidebar.feeds.sources")
        case .settings:
            return String.localized("sidebar.settings.detail")
        }
    }
}

private struct SidebarRow: View {
    let title: String
    let detail: String?
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(1)

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
