import SwiftUI
import DSGetCore

struct TaskDetailWindowView: View {
    @Environment(AppViewModel.self) private var appViewModel

    let taskID: TaskID?

    private var task: DownloadTask? {
        guard let taskID else { return nil }
        return appViewModel.tasksViewModel.tasks.first(where: { $0.id == taskID })
    }

    var body: some View {
        Group {
            if let task {
                NavigationStack {
                    TaskDetailView(task: task)
                }
            } else {
                ContentUnavailableView(
                    String.localized("mac.detailWindow.taskUnavailable"),
                    systemImage: "tray",
                    description: Text(String.localized("mac.detailWindow.taskUnavailable.description"))
                )
            }
        }
        .frame(minWidth: 520, minHeight: 560)
    }
}
