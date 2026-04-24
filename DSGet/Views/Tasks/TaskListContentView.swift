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

    private var toolbarFilterPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .automatic
        #else
        .topBarLeading
        #endif
    }

    var body: some View {
        @Bindable var vm = tasksVM

        #if os(macOS)
        AdaptiveLayoutReader { width in
            taskListContent(
                selectedTask: $vm.selectedTask,
                searchText: $vm.searchText,
                layoutWidth: width
            )
        }
        #else
        taskListContent(
            selectedTask: $vm.selectedTask,
            searchText: $vm.searchText
        )
        #endif
    }

    @ViewBuilder
    private func taskListContent(
        selectedTask: Binding<DownloadTask?>,
        searchText: Binding<String>,
        layoutWidth: AdaptiveLayoutWidth? = nil
    ) -> some View {
        let content = VStack(spacing: 0) {
            #if os(macOS)
            if let layoutWidth {
                TaskTransferHeader(
                    layoutWidth: layoutWidth,
                    tasksViewModel: tasksVM,
                    statusFilter: statusFilter,
                    onStatusFilterChange: onStatusFilterChange,
                    addTaskButton: addTaskButton,
                    usesCompactToolbarLayout: usesCompactToolbarLayout
                )
            }
            #endif

            TaskListSelectionView(
                tasks: tasksVM.visibleTasks,
                selectedTask: selectedTask,
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
        #endif
        .toolbar {
            #if os(macOS)
            ToolbarItemGroup(placement: .primaryAction) {
                refreshButton
                addTaskButton
                    .labelStyle(.iconOnly)
                    .help(String.localized("tasks.button.addTask"))
            }
            #endif

            ToolbarItemGroup(placement: toolbarFilterPlacement) {
                HStack(spacing: 12) {
                    TaskFilterMenu(
                        viewModel: tasksVM,
                        statusFilter: statusFilter,
                        onStatusFilterChange: onStatusFilterChange
                    )
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

        #if os(macOS)
        content
        #else
        if usesCompactToolbarLayout {
            content.searchable(text: searchText, prompt: String.localized("tasks.search.prompt"))
        } else {
            content
        }
        #endif
    }

    private var addTaskButton: some View {
        Button(String.localized("tasks.button.addTask"), systemImage: "plus", action: presentAddTask)
            .accessibilityIdentifier(AccessibilityID.TaskList.addButton)
    }

    private var refreshButton: some View {
        Button {
            Task { await tasksVM.refresh() }
        } label: {
            Label(String.localized("quickAction.refresh"), systemImage: "arrow.clockwise")
        }
        .disabled(tasksVM.isLoading)
        .help(String.localized("quickAction.refresh"))
    }

    private func addTaskSheet(_ preselectedTorrent: AddTaskPreselectedTorrent) -> some View {
        NavigationStack {
            AddTaskView(preselectedTorrent: preselectedTorrent)
        }
    }

    @ViewBuilder
    private var taskStateOverlay: some View {
        switch taskContentState {
        case .loading:
            ProgressView(String.localized("tasks.state.loading.title"))
        case .offline:
            ContentUnavailableView {
                Label(String.localized(EmptyStateText.offlineTitle), systemImage: "wifi.slash")
            } description: {
                Text(String.localized(EmptyStateText.offlineDescription))
            } actions: {
                Button(String.localized(EmptyStateText.offlineAction), action: retryTasks)
            }
        case .error(let error):
            ContentUnavailableView {
                Label(error.requiresRelogin ? String.localized("state.permission.title") : String.localized(EmptyStateText.errorTitle),
                      systemImage: error.requiresRelogin ? "lock.shield" : "exclamationmark.triangle")
            } description: {
                Text(error.requiresRelogin ? String.localized("state.permission.description") : error.localizedDescription)
            } actions: {
                Button(String.localized(EmptyStateText.errorAction), action: retryTasks)
            }
        case .empty:
            ContentUnavailableView {
                Label(String.localized(EmptyStateText.noTasksTitle), systemImage: "arrow.down.circle")
            } description: {
                Text(String.localized(EmptyStateText.noTasksDescription))
            } actions: {
                Button(String.localized("tasks.button.addTask"), action: presentAddTask)
            }
        case .noResults:
            ContentUnavailableView {
                Label(String.localized("tasks.state.noResults.title"), systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text(taskNoResultsDescription)
            } actions: {
                Button(String.localized("state.clearFilters"), action: clearTaskFilters)
            }
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
