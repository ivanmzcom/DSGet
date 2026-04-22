//
//  TaskListContentView.swift
//  DSGet
//
//  Created by Iván Moreno Zambudio on 26/9/25.
//

import SwiftUI
import DSGetCore

// MARK: - Task List Content View (Column 2 for Tasks)

struct TaskListContentView: View {
    @Environment(AppViewModel.self) private var appViewModel
    var statusFilter: TaskStatusFilter = .all
    var onStatusFilterChange: ((TaskStatusFilter) -> Void)?
    var opensTaskDetailInWindow = false

    #if !os(macOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var preselectedTorrent: AddTaskPreselectedTorrent?

    private var tasksVM: TasksViewModel { appViewModel.tasksViewModel }

    private var usesCompactToolbarLayout: Bool {
        #if os(macOS)
        false
        #else
        horizontalSizeClass == .compact
        #endif
    }

    var body: some View {
        @Bindable var vm = tasksVM

        AdaptiveLayoutReader { width in
            VStack(spacing: 0) {
                TaskTransferHeader(
                    layoutWidth: width,
                    tasksViewModel: tasksVM,
                    statusFilter: statusFilter,
                    onStatusFilterChange: onStatusFilterChange,
                    addTaskButton: addTaskButton,
                    usesCompactToolbarLayout: usesCompactToolbarLayout
                )

                TaskListSelectionView(
                    tasks: tasksVM.visibleTasks,
                    selectedTask: $vm.selectedTask,
                    onDelete: handleDeleteTask,
                    onTogglePause: handleTogglePause,
                    opensTaskDetailInWindow: opensTaskDetailInWindow
                )
            }
            .navigationTitle(String.localized("tasks.title"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, prompt: String.localized("tasks.search.prompt"))
            #endif
            .toolbar {
                ToolbarItem(placement: toolbarFilterPlacement) {
                    HStack(spacing: 12) {
                        TaskTypeFilterMenu(viewModel: tasksVM, selectedTaskTypeLabel: selectedTaskTypeLabel)
                        TaskSortMenu(viewModel: tasksVM)
                    }
                }
            }
            .task {
                tasksVM.statusFilter = statusFilter
                await tasksVM.fetchTasks()
            }
            .onChange(of: statusFilter) { _, newValue in
                tasksVM.statusFilter = newValue
            }
            .loadingOverlay(
                isLoading: tasksVM.isLoading,
                isEmpty: tasksVM.visibleTasks.isEmpty,
                title: String.localized(EmptyStateText.noTasksTitle),
                systemImage: "checklist",
                description: "Add a new download task using the + button."
            )
            .errorAlert(isPresented: $vm.showingError, error: tasksVM.currentError)
            .onChange(of: appViewModel.incomingTorrentURL) { _, newValue in
                guard let url = newValue else { return }
                Task { await importTorrent(from: url) }
            }
            .sheet(item: $preselectedTorrent, content: addTaskSheet)
            .offlineModeIndicator(isOffline: tasksVM.isOfflineMode)
        }
    }

    private var addTaskButton: some View {
        Button(String.localized("tasks.button.addTask"), systemImage: "plus", action: presentAddTask)
            .accessibilityIdentifier(AccessibilityID.TaskList.addButton)
    }

    private var toolbarFilterPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .topBarLeading
        #endif
    }

    private func addTaskSheet(_ preselectedTorrent: AddTaskPreselectedTorrent) -> some View {
        NavigationStack {
            AddTaskView(
                preselectedTorrent: preselectedTorrent
            )
        }
    }

    private var selectedTaskTypeLabel: String {
        switch tasksVM.taskTypeFilter {
        case .all: "BT/E2K"
        case .bt: "BT"
        case .e2k: "E2K"
        }
    }

    private func presentAddTask() {
        appViewModel.presentAddTask()
    }

    private func handleDeleteTask(task: DownloadTask) {
        Task {
            await tasksVM.deleteTask(task)
        }
    }

    private func handleTogglePause(task: DownloadTask) {
        Task {
            await tasksVM.togglePause(task)
        }
    }

    private func importTorrent(from url: URL) async {
        do {
            let attachment = try tasksVM.importTorrentFile(from: url)

            await MainActor.run {
                preselectedTorrent = attachment
                appViewModel.incomingTorrentURL = nil
            }
        } catch {
            await MainActor.run {
                appViewModel.incomingTorrentURL = nil
                tasksVM.currentError = .network(.requestFailed(reason: error.localizedDescription))
                tasksVM.showingError = true
            }
        }
    }
}

private struct TaskListSelectionView: View {
    let tasks: [DownloadTask]
    @Binding var selectedTask: DownloadTask?

    let onDelete: (DownloadTask) -> Void
    let onTogglePause: (DownloadTask) -> Void
    let opensTaskDetailInWindow: Bool

    var body: some View {
        #if os(macOS)
        TaskTableView(
            tasks: tasks,
            selectedTask: $selectedTask,
            onDelete: onDelete,
            onTogglePause: onTogglePause,
            opensTaskDetailInWindow: opensTaskDetailInWindow
        )
        #else
        List(selection: $selectedTask) {
            ForEach(tasks) { task in
                TaskListItemView(
                    task: task,
                    isSelected: selectedTask?.id == task.id,
                    opensDetailInWindowOnDoubleClick: opensTaskDetailInWindow,
                    onDelete: onDelete,
                    onTogglePause: onTogglePause
                )
                    .tag(task)
                    .accessibilityIdentifier("\(AccessibilityID.TaskList.taskRow).\(task.id.rawValue)")
            }
        }
        .listStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.TaskList.list)
        #endif
    }
}

private struct TaskTransferHeader<AddButton: View>: View {
    let layoutWidth: AdaptiveLayoutWidth
    let tasksViewModel: TasksViewModel
    let statusFilter: TaskStatusFilter
    let onStatusFilterChange: ((TaskStatusFilter) -> Void)?
    let addTaskButton: AddButton
    let usesCompactToolbarLayout: Bool

    private var totalCount: Int { tasksViewModel.tasks.count }
    private var downloadingCount: Int { tasksViewModel.tasks.filter(\.isDownloading).count }
    private var pausedCount: Int { tasksViewModel.tasks.filter(\.isPaused).count }
    private var completedCount: Int { tasksViewModel.tasks.filter(\.isCompleted).count }

    private var totalDownloadSpeed: String {
        ByteSize(bytes: tasksViewModel.visibleTasks.reduce(0) { $0 + $1.downloadSpeed.bytes }).formatted
    }

    private var totalUploadSpeed: String {
        ByteSize(bytes: tasksViewModel.visibleTasks.reduce(0) { $0 + $1.uploadSpeed.bytes }).formatted
    }

    var body: some View {
        #if os(iOS)
        iosHeader
        #else
        macHeader
        #endif
    }

    #if os(iOS)
    private var iosHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Transfers")
                        .font(.title3.weight(.semibold))
                    Text("\(totalCount) items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if layoutWidth == .compact {
                    addTaskButton
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                } else {
                    addTaskButton
                        .labelStyle(.titleAndIcon)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 8)

            if let onStatusFilterChange {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TaskStatusChip(title: "All", count: totalCount, isSelected: statusFilter == .all) {
                            onStatusFilterChange(.all)
                        }
                        TaskStatusChip(title: "Downloading", count: downloadingCount, isSelected: statusFilter == .downloading) {
                            onStatusFilterChange(.downloading)
                        }
                        TaskStatusChip(title: "Paused", count: pausedCount, isSelected: statusFilter == .paused) {
                            onStatusFilterChange(.paused)
                        }
                        TaskStatusChip(title: "Completed", count: completedCount, isSelected: statusFilter == .completed) {
                            onStatusFilterChange(.completed)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }

            Divider()
        }
        .background(.bar)
    }
    #endif

    private var macHeader: some View {
        VStack(spacing: 0) {
            if layoutWidth == .compact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Transfers")
                                .font(.headline)
                            Text("\(totalCount) items")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        addTaskButton
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 12) {
                        transferStat(title: "D", value: totalDownloadSpeed + "/s")
                        transferStat(title: "U", value: totalUploadSpeed + "/s")
                        transferStat(title: "A", value: "\(downloadingCount)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Transfers")
                            .font(.title3.weight(.semibold))
                        Text("\(totalCount) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        transferStat(title: "Down", value: totalDownloadSpeed + "/s")
                        transferStat(title: "Up", value: totalUploadSpeed + "/s")
                        transferStat(title: "Active", value: "\(downloadingCount)")
                    }

                    addTaskButton
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }

            if !usesCompactToolbarLayout, let onStatusFilterChange {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TaskStatusChip(title: "All", count: totalCount, isSelected: statusFilter == .all) {
                            onStatusFilterChange(.all)
                        }
                        TaskStatusChip(title: "Downloading", count: downloadingCount, isSelected: statusFilter == .downloading) {
                            onStatusFilterChange(.downloading)
                        }
                        TaskStatusChip(title: "Paused", count: pausedCount, isSelected: statusFilter == .paused) {
                            onStatusFilterChange(.paused)
                        }
                        TaskStatusChip(title: "Completed", count: completedCount, isSelected: statusFilter == .completed) {
                            onStatusFilterChange(.completed)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                }
            }

            Divider()
        }
        .background(.bar)
    }

    private func transferStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit())
        }
        .frame(minWidth: 56, alignment: .leading)
    }
}

private struct TaskStatusChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                Text("\(count)")
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct TaskStatusFilterMenu: View {
    let statusFilter: TaskStatusFilter
    let onStatusFilterChange: (TaskStatusFilter) -> Void

    var body: some View {
        Menu {
            ForEach(TaskStatusFilter.allCases) { filter in
                Button {
                    onStatusFilterChange(filter)
                } label: {
                    if filter == statusFilter {
                        Label(filter.label, systemImage: "checkmark")
                    } else {
                        Text(filter.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(statusFilter.label)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
}

#if os(macOS)
private struct TaskTableView: View {
    @Environment(\.openWindow) private var openWindow

    let tasks: [DownloadTask]
    @Binding var selectedTask: DownloadTask?
    let onDelete: (DownloadTask) -> Void
    let onTogglePause: (DownloadTask) -> Void
    let opensTaskDetailInWindow: Bool

    var body: some View {
        Table(of: DownloadTask.self) {
            TableColumn("Name") { task in
                TaskNameTableCell(task: task)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTask = task
                    }
                    .onTapGesture(count: 2) {
                        selectedTask = task
                        guard opensTaskDetailInWindow else { return }
                        openWindow(value: task.id)
                    }
                    .contextMenu {
                        taskContextMenu(for: task)
                    }
            }
            .width(min: 280, ideal: 480)

            TableColumn("Progress") { task in
                VStack(alignment: .trailing, spacing: 4) {
                    Text(taskPercent(task))
                        .font(.body.monospacedDigit())
                    ProgressView(value: task.progress)
                        .tint(TaskStatusPresentation(status: task.status).color)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(90)

            TableColumn("Down") { task in
                Text(task.transfer?.formattedDownloadSpeed ?? "0 B/s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(90)

            TableColumn("Up") { task in
                Text(task.transfer?.formattedUploadSpeed ?? "0 B/s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(90)

            TableColumn("Status") { task in
                Text(TaskStatusPresentation(status: task.status).text)
                    .font(.caption)
                    .foregroundStyle(TaskStatusPresentation(status: task.status).color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .width(110)
        } rows: {
            ForEach(tasks) { task in
                TableRow(task)
            }
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
                        Text("Ratio \(String(format: "%.2f", task.shareRatio))")
                    }
                    if task.peers > 0 {
                        Text("Peers \(task.peers)")
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

private struct TaskTypeFilterMenu: View {
    let viewModel: TasksViewModel
    let selectedTaskTypeLabel: String

    var body: some View {
        @Bindable var viewModel = viewModel

        Menu {
            Picker(String.localized("tasks.type.filter"), selection: $viewModel.taskTypeFilter) {
                ForEach(TaskTypeFilter.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            if !viewModel.searchText.isEmpty {
                Button(String.localized("tasks.search.clear"), systemImage: "xmark.circle") {
                    viewModel.searchText = ""
                }
            }
        } label: {
            Label(selectedTaskTypeLabel, systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

private struct TaskSortMenu: View {
    let viewModel: TasksViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        Menu {
            Picker(String.localized("tasks.sort.by"), selection: $viewModel.sortKey) {
                ForEach(TaskSortKey.allCases) { key in
                    Text(key.label).tag(key)
                }
            }

            Picker(String.localized("tasks.sort.order"), selection: $viewModel.sortDirection) {
                ForEach(TaskSortDirection.allCases) { direction in
                    Label(direction.rawValue, systemImage: direction.symbol).tag(direction)
                }
            }
        } label: {
            Label(viewModel.sortKey.label, systemImage: viewModel.sortDirection.symbol)
        }
    }
}
