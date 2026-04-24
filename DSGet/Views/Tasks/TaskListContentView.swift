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
            .overlay {
                taskStateOverlay
            }
            .navigationTitle(String.localized("tasks.title"))
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, prompt: String.localized("tasks.search.prompt"))
            #endif
            .toolbar {
                #if os(macOS)
                ToolbarItemGroup(placement: .primaryAction) {
                    Button {
                        Task { await tasksVM.refresh() }
                    } label: {
                        Label(String.localized("quickAction.refresh"), systemImage: "arrow.clockwise")
                    }
                    .disabled(tasksVM.isLoading)
                    .help(String.localized("quickAction.refresh"))

                    addTaskButton
                        .labelStyle(.iconOnly)
                        .help(String.localized("tasks.button.addTask"))
                }
                #endif

                ToolbarItemGroup(placement: toolbarFilterPlacement) {
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
            .errorAlert(isPresented: taskErrorAlertBinding, error: tasksVM.currentError)
            .onChange(of: appViewModel.incomingTorrentURL) { _, newValue in
                guard let url = newValue else { return }
                Task { await importTorrent(from: url) }
            }
            .sheet(item: $preselectedTorrent, content: addTaskSheet)
            .offlineModeIndicator(isOffline: shouldShowOfflineBadge)
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
        tasksVM.taskTypeFilter.localizedShortLabel
    }

    private var taskContentState: TaskListContentState? {
        if tasksVM.isLoading && tasksVM.tasks.isEmpty {
            return .loading
        }

        if let currentError = tasksVM.currentError, tasksVM.tasks.isEmpty {
            return .error(currentError)
        }

        if tasksVM.isOfflineMode && tasksVM.tasks.isEmpty {
            return .offline
        }

        if tasksVM.tasks.isEmpty {
            return .empty
        }

        if tasksVM.visibleTasks.isEmpty && hasActiveTaskFilters {
            return .noResults
        }

        return nil
    }

    private var hasActiveTaskFilters: Bool {
        !tasksVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            tasksVM.taskTypeFilter != .all ||
            statusFilter != .all
    }

    private var shouldShowOfflineBadge: Bool {
        tasksVM.isOfflineMode && taskContentState == nil
    }

    private var taskErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { tasksVM.showingError && !isShowingInlineError },
            set: { tasksVM.showingError = $0 }
        )
    }

    private var isShowingInlineError: Bool {
        if case .error = taskContentState {
            return true
        }
        return false
    }

    @ViewBuilder
    private var taskStateOverlay: some View {
        switch taskContentState {
        case .loading:
            DSGetLoadingContentStateView(
                title: String.localized("tasks.state.loading.title"),
                description: String.localized("tasks.state.loading.description")
            )
        case .offline:
            DSGetContentStateView.offline(onRetry: retryTasks)
        case .error(let error):
            DSGetContentStateView.error(error, onRetry: retryTasks)
        case .empty:
            DSGetContentStateView(
                title: String.localized(EmptyStateText.noTasksTitle),
                description: String.localized(EmptyStateText.noTasksDescription),
                systemImage: "arrow.down.circle",
                primaryActionTitle: String.localized("tasks.button.addTask"),
                primaryAction: presentAddTask
            )
        case .noResults:
            DSGetContentStateView(
                title: String.localized("tasks.state.noResults.title"),
                description: taskNoResultsDescription,
                systemImage: "line.3.horizontal.decrease.circle",
                primaryActionTitle: String.localized("state.clearFilters"),
                primaryAction: clearTaskFilters
            )
        case nil:
            EmptyView()
        }
    }

    private var taskNoResultsDescription: String {
        let query = tasksVM.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasSearch = !query.isEmpty
        let hasNonSearchFilters = tasksVM.taskTypeFilter != .all || statusFilter != .all

        if hasSearch && hasNonSearchFilters {
            return String.localized("tasks.state.noResults.searchAndFilters", query)
        }

        if hasSearch {
            return String.localized("tasks.state.noResults.search", query)
        }

        return String.localized("tasks.state.noResults.filters")
    }

    private func presentAddTask() {
        appViewModel.presentAddTask()
    }

    private func retryTasks() {
        Task { await tasksVM.fetchTasks(forceRefresh: true) }
    }

    private func clearTaskFilters() {
        tasksVM.searchText = ""
        tasksVM.taskTypeFilter = .all
        tasksVM.statusFilter = .all
        onStatusFilterChange?(.all)
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

private enum TaskListContentState {
    case loading
    case offline
    case error(DSGetError)
    case empty
    case noResults
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
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .dsgetContentBackground()
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
                DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String.localized("tasks.header.transfers"))
                        .font(.title3.weight(.semibold))
                    Text(String.localized("tasks.header.items", totalCount))
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
                        TaskStatusChip(title: TaskStatusFilter.all.localizedLabel, count: totalCount, isSelected: statusFilter == .all) {
                            onStatusFilterChange(.all)
                        }
                        TaskStatusChip(title: TaskStatusFilter.downloading.localizedLabel, count: downloadingCount, isSelected: statusFilter == .downloading) {
                            onStatusFilterChange(.downloading)
                        }
                        TaskStatusChip(title: TaskStatusFilter.paused.localizedLabel, count: pausedCount, isSelected: statusFilter == .paused) {
                            onStatusFilterChange(.paused)
                        }
                        TaskStatusChip(title: TaskStatusFilter.completed.localizedLabel, count: completedCount, isSelected: statusFilter == .completed) {
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
                        DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String.localized("tasks.header.transfers"))
                                .font(.headline)
                            Text(String.localized("tasks.header.items", totalCount))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: 0)

                        addTaskButton
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderedProminent)
                    }

                    HStack(spacing: 12) {
                        transferStat(title: String.localized("tasks.header.down"), value: totalDownloadSpeed + "/s")
                        transferStat(title: String.localized("tasks.header.up"), value: totalUploadSpeed + "/s")
                        transferStat(title: String.localized("tasks.header.active"), value: "\(downloadingCount)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)
            } else {
                HStack(alignment: .center, spacing: 14) {
                    DSGetIconBadge(systemName: "arrow.down.circle.fill", tint: .accentColor, size: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(String.localized("tasks.header.transfers"))
                            .font(.title3.weight(.semibold))
                        Text(String.localized("tasks.header.items", totalCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: 10) {
                        transferStat(title: String.localized("tasks.header.down"), value: totalDownloadSpeed + "/s")
                        transferStat(title: String.localized("tasks.header.up"), value: totalUploadSpeed + "/s")
                        transferStat(title: String.localized("tasks.header.active"), value: "\(downloadingCount)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 10)
            }

            if !usesCompactToolbarLayout, let onStatusFilterChange {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TaskStatusChip(title: TaskStatusFilter.all.localizedLabel, count: totalCount, isSelected: statusFilter == .all) {
                            onStatusFilterChange(.all)
                        }
                        TaskStatusChip(title: TaskStatusFilter.downloading.localizedLabel, count: downloadingCount, isSelected: statusFilter == .downloading) {
                            onStatusFilterChange(.downloading)
                        }
                        TaskStatusChip(title: TaskStatusFilter.paused.localizedLabel, count: pausedCount, isSelected: statusFilter == .paused) {
                            onStatusFilterChange(.paused)
                        }
                        TaskStatusChip(title: TaskStatusFilter.completed.localizedLabel, count: completedCount, isSelected: statusFilter == .completed) {
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
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .background(
                isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08),
                in: RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DSGetDesign.cornerRadius, style: .continuous)
                    .stroke(isSelected ? Color.accentColor.opacity(0.35) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
                        Label(filter.localizedLabel, systemImage: "checkmark")
                    } else {
                        Text(filter.localizedLabel)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(statusFilter.localizedLabel)
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
        Table(tasks, selection: selectedTaskID) {
            TableColumn(String.localized("tasks.table.name")) { task in
                TaskNameTableCell(task: task)
                    .contentShape(Rectangle())
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

    private var selectedTaskID: Binding<TaskID?> {
        Binding(
            get: { selectedTask?.id },
            set: { taskID in
                selectedTask = tasks.first { $0.id == taskID }
            }
        )
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

private struct TaskTypeFilterMenu: View {
    let viewModel: TasksViewModel
    let selectedTaskTypeLabel: String

    var body: some View {
        @Bindable var viewModel = viewModel

        Menu {
            Picker(String.localized("tasks.type.filter"), selection: $viewModel.taskTypeFilter) {
                ForEach(TaskTypeFilter.allCases) { type in
                    Text(type.localizedShortLabel).tag(type)
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
                    Text(key.localizedLabel).tag(key)
                }
            }

            Picker(String.localized("tasks.sort.order"), selection: $viewModel.sortDirection) {
                ForEach(TaskSortDirection.allCases) { direction in
                    Label(direction.localizedLabel, systemImage: direction.symbol).tag(direction)
                }
            }
        } label: {
            Label(viewModel.sortKey.localizedLabel, systemImage: viewModel.sortDirection.symbol)
        }
    }
}

private extension TaskStatusFilter {
    var localizedLabel: String {
        switch self {
        case .all: String.localized("tasks.filter.all")
        case .downloading: String.localized("tasks.filter.downloading")
        case .paused: String.localized("tasks.filter.paused")
        case .completed: String.localized("tasks.filter.completed")
        }
    }
}

private extension TaskTypeFilter {
    var localizedShortLabel: String {
        switch self {
        case .all: String.localized("tasks.type.all")
        case .bt: String.localized("tasks.type.bt")
        case .e2k: String.localized("tasks.type.e2k")
        }
    }
}

private extension TaskSortKey {
    var localizedLabel: String {
        switch self {
        case .date: String.localized("tasks.sort.date")
        case .name: String.localized("tasks.sort.name")
        case .downloadSpeed: String.localized("tasks.sort.downloadSpeed")
        case .uploadSpeed: String.localized("tasks.sort.uploadSpeed")
        }
    }
}

private extension TaskSortDirection {
    var localizedLabel: String {
        switch self {
        case .ascending: String.localized("tasks.sort.ascending")
        case .descending: String.localized("tasks.sort.descending")
        }
    }
}
