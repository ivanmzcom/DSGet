import SwiftUI
import DSGetCore

struct MainDetailColumn: View {
    let appViewModel: AppViewModel
    let selectedSection: AppSection?

    private var tasksViewModel: TasksViewModel { appViewModel.tasksViewModel }
    private var feedsViewModel: FeedsViewModel { appViewModel.feedsViewModel }

    var body: some View {
        switch selectedSection {
        case .downloads:
            if let task = tasksViewModel.selectedTask {
                TaskDetailView(
                    task: task,
                    onTaskUpdated: refreshTasks,
                    onClose: closeTask
                )
                .id(task.id)
            } else {
                ContentUnavailableView(
                    String.localized("tasks.selectTask"),
                    systemImage: "arrow.down.circle"
                )
            }
        case .feeds:
            if let feed = selectedFeed {
                FeedDetailView(feed: feed, onClose: closeFeed)
                    .id(feed.id)
            } else {
                ContentUnavailableView(
                    String.localized("feeds.selectFeed"),
                    systemImage: "dot.radiowaves.left.and.right"
                )
            }
        case .settings, nil:
            ContentUnavailableView(
                String.localized("settings.title"),
                systemImage: "gear"
            )
        }
    }

    private var selectedFeed: RSSFeed? {
        guard let feedID = feedsViewModel.selectedFeedID else { return nil }
        return feedsViewModel.feeds.first(where: { $0.id == feedID })
    }

    private func refreshTasks() {
        Task { await tasksViewModel.fetchTasks(forceRefresh: true) }
    }

    private func closeTask() {
        tasksViewModel.selectedTask = nil
    }

    private func closeFeed() {
        feedsViewModel.selectedFeedID = nil
    }
}
