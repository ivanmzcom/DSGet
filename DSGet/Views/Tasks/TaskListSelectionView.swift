//
//  TaskListSelectionView.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct TaskListSelectionView: View {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif

    let tasks: [DownloadTask]
    @Binding var selectedTaskID: TaskID?

    let onDelete: (DownloadTask) -> Void
    let onTogglePause: (DownloadTask) -> Void
    let opensTaskDetailInWindow: Bool

    var body: some View {
        #if os(macOS)
        TaskTableView(
            tasks: tasks,
            selectedTaskID: $selectedTaskID,
            onDelete: onDelete,
            onTogglePause: onTogglePause,
            opensTaskDetailInWindow: opensTaskDetailInWindow
        )
        #else
        if horizontalSizeClass == .compact {
            List(tasks) { task in
                NavigationLink {
                    TaskDetailView(task: task)
                } label: {
                    taskRow(task)
                }
                .accessibilityIdentifier("\(AccessibilityID.TaskList.taskRow).\(task.id.rawValue)")
            }
            .accessibilityIdentifier(AccessibilityID.TaskList.list)
        } else {
            List {
                ForEach(tasks) { task in
                    let isSelected = selectedTaskID == task.id
                    taskRow(task)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTaskID = task.id
                        }
                        .listRowBackground(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("\(AccessibilityID.TaskList.taskRow).\(task.id.rawValue)")
                }
            }
            .accessibilityIdentifier(AccessibilityID.TaskList.list)
        }
        #endif
    }

    private func taskRow(_ task: DownloadTask) -> some View {
        TaskListItemView(
            task: task,
            isSelected: selectedTaskID == task.id,
            opensDetailInWindowOnDoubleClick: opensTaskDetailInWindow,
            onDelete: onDelete,
            onTogglePause: onTogglePause
        )
    }
}

#if os(macOS)
private struct TaskTableView: View {
    @Environment(\.openWindow) private var openWindow

    let tasks: [DownloadTask]
    @Binding var selectedTaskID: TaskID?
    let onDelete: (DownloadTask) -> Void
    let onTogglePause: (DownloadTask) -> Void
    let opensTaskDetailInWindow: Bool

    var body: some View {
        Table(tasks, selection: $selectedTaskID) {
            TableColumn(String.localized("tasks.table.name")) { task in
                TaskNameTableCell(task: task)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        selectedTaskID = task.id
                        guard opensTaskDetailInWindow else { return }
                        openWindow(value: task.id)
                    }
                    .contextMenu {
                        taskContextMenu(for: task)
                    }
            }
            .width(min: 280, ideal: 480)

            TableColumn(String.localized("tasks.table.progress")) { task in
                VStack(alignment: .trailing, spacing: 4) {
                    Text(taskPercent(task))
                        .font(.body.monospacedDigit())
                    ProgressView(value: task.progress)
                        .tint(TaskStatusPresentation(status: task.status).color)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(90)

            TableColumn(String.localized("tasks.header.down")) { task in
                Text(task.transfer?.formattedDownloadSpeed ?? "0 B/s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(90)

            TableColumn(String.localized("tasks.header.up")) { task in
                Text(task.transfer?.formattedUploadSpeed ?? "0 B/s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(90)

            TableColumn(String.localized("tasks.table.status")) { task in
                Text(TaskStatusPresentation(status: task.status).text)
                    .font(.caption)
                    .foregroundStyle(TaskStatusPresentation(status: task.status).color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(110)
        }
        .accessibilityIdentifier(AccessibilityID.TaskList.list)
    }

    @ViewBuilder
    private func taskContextMenu(for task: DownloadTask) -> some View {
        Button {
            onTogglePause(task)
        } label: {
            Label(
                task.isPaused
                    ? String.localized("taskItem.action.resume")
                    : String.localized("taskItem.action.pause"),
                systemImage: task.isPaused ? "play.fill" : "pause.fill"
            )
        }
        .disabled(task.type == .emule && task.isCompleted)

        Button(role: .destructive) {
            onDelete(task)
        } label: {
            Label(String.localized("taskItem.action.delete"), systemImage: "trash")
        }
    }

    private func taskPercent(_ task: DownloadTask) -> String {
        "\(Int(task.progress * 100))%"
    }
}

private struct TaskNameTableCell: View {
    let task: DownloadTask

    private var status: TaskStatusPresentation {
        TaskStatusPresentation(status: task.status)
    }

    private var sizeText: String {
        "\(task.downloadedSize.formatted) of \(task.size.formatted)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: task.type == .bt ? "arrow.down.circle" : "tray.full")
                .foregroundStyle(status.color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(sizeText)
                    if task.shareRatio > 0 {
                        Text(String.localized("taskItem.ratio", String(format: "%.2f", task.shareRatio)))
                    }
                    if task.peers > 0 {
                        Text(String.localized("taskItem.peers", task.peers))
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
#endif
