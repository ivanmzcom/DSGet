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
                    "Task Not Available",
                    systemImage: "tray",
                    description: Text("Refresh the task list and try again.")
                )
            }
        }
        .frame(minWidth: 520, minHeight: 560)
    }
}
