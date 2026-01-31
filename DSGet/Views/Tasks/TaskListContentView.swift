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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var preselectedTorrent: AddTaskPreselectedTorrent?
    @State private var localIsShowingAddTask = false

    // Convenience accessor
    private var tasksVM: TasksViewModel { appViewModel.tasksViewModel }

    // MARK: - Toolbar Views

    @ViewBuilder
    private func statusFilterMenu() -> some View {
        if let onStatusFilterChange {
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

    @ViewBuilder
    private func taskTypeMenu() -> some View {
        @Bindable var vm = tasksVM
        Menu {
            Picker(String.localized("tasks.type.filter"), selection: $vm.taskTypeFilter) {
                ForEach(TaskTypeFilter.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            if !tasksVM.searchText.isEmpty {
                Button(String.localized("tasks.search.clear"), systemImage: "xmark.circle") {
                    tasksVM.searchText = ""
                }
            }
        } label: {
            Label(selectedTaskTypeLabel, systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    @ViewBuilder
    private func sortMenu() -> some View {
        @Bindable var vm = tasksVM
        Menu {
            Picker(String.localized("tasks.sort.by"), selection: $vm.sortKey) {
                ForEach(TaskSortKey.allCases) { key in
                    Text(key.label).tag(key)
                }
            }
            Picker(String.localized("tasks.sort.order"), selection: $vm.sortDirection) {
                ForEach(TaskSortDirection.allCases) { direction in
                    Label(direction.rawValue, systemImage: direction.symbol).tag(direction)
                }
            }
        } label: {
            Label(tasksVM.sortKey.label, systemImage: tasksVM.sortDirection.symbol)
        }
    }

    // MARK: - Sheet Views

    @ViewBuilder
    private func addTaskSheet() -> some View {
        NavigationStack {
            AddTaskView(preselectedTorrent: preselectedTorrent, prefilledURL: appViewModel.prefilledAddTaskURL)
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private func taskListContent() -> some View {
        @Bindable var vm = tasksVM
        List(tasksVM.visibleTasks, selection: $vm.selectedTask) { task in
            TaskListItemView(task: task, onDelete: handleDeleteTask, onTogglePause: handleTogglePause)
                .tag(task)
                .accessibilityIdentifier("\(AccessibilityID.TaskList.taskRow).\(task.id.rawValue)")
        }
        .listStyle(.plain)
        .accessibilityIdentifier(AccessibilityID.TaskList.list)
    }

    var body: some View {
        @Bindable var vm = tasksVM

        taskListContent()
            .navigationTitle(String.localized("tasks.title"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, prompt: String.localized("tasks.search.prompt"))
            .toolbar {
                if horizontalSizeClass == .compact {
                    ToolbarItem(placement: .principal) {
                        statusFilterMenu()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        taskTypeMenu()
                        sortMenu()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(String.localized("tasks.button.addTask"), systemImage: "plus") {
                        preselectedTorrent = nil
                        appViewModel.prefilledAddTaskURL = nil
                        appViewModel.isShowingAddTask = true
                    }
                    .accessibilityIdentifier(AccessibilityID.TaskList.addButton)
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
            .sheet(
                isPresented: $localIsShowingAddTask,
                onDismiss: { preselectedTorrent = nil },
                content: { addTaskSheet() }
            )
            .offlineModeIndicator(isOffline: tasksVM.isOfflineMode)
    }

    var selectedTaskTypeLabel: String {
        switch tasksVM.taskTypeFilter {
        case .all: "BT/E2K"
        case .bt: "BT"
        case .e2k: "E2K"
        }
    }

    // MARK: - Actions

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
                appViewModel.prefilledAddTaskURL = nil
                localIsShowingAddTask = true
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
