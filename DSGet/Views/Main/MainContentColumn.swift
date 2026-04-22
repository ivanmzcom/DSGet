import SwiftUI
import DSGetCore

struct MainContentColumn: View {
    let appViewModel: AppViewModel
    let selectedSection: AppSection?
    @Binding var statusFilter: TaskStatusFilter

    var body: some View {
        switch selectedSection {
        case .downloads:
            #if os(macOS)
            TaskListContentView(
                statusFilter: statusFilter,
                onStatusFilterChange: { statusFilter = $0 },
                opensTaskDetailInWindow: true
            )
            #else
            TaskListContentView(
                statusFilter: statusFilter,
                onStatusFilterChange: { statusFilter = $0 }
            )
            #endif
        case .feeds:
            FeedListContentView(
                favoriteFeedIDs: appViewModel.feedsViewModel.favoriteFeedIDs,
                onToggleFavorite: appViewModel.feedsViewModel.toggleFavorite
            )
        case .settings:
            SettingsView()
        case nil:
            ContentUnavailableView(
                String.localized("tab.downloads"),
                systemImage: "sidebar.left"
            )
        }
    }
}
