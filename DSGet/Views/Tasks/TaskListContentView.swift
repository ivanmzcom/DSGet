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
    var onStatusFilterChange: ((TaskStatusFilter) -> Void)? = nil

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var preselectedTorrent: AddTaskPreselectedTorrent?
    @State private var localIsShowingAddTask = false

    // Convenience accessor
    private var tasksVM: TasksViewModel { appViewModel.tasksViewModel }

    // MARK: - Toolbar Views

    @ViewBuilder
    private func statusFilterMenu() -> some View {
        if let onStatusFilterChange = onStatusFilterChange {
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
            Picker("Task Type", selection: $vm.taskTypeFilter) {
                ForEach(TaskTypeFilter.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            if !tasksVM.searchText.isEmpty {
                Button("Clear Search", systemImage: "xmark.circle") {
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
            Picker("Sort By", selection: $vm.sortKey) {
                ForEach(TaskSortKey.allCases) { key in
                    Text(key.label).tag(key)
                }
            }
            Picker("Order", selection: $vm.sortDirection) {
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
        }
        .listStyle(.sidebar)
    }

    var body: some View {
        @Bindable var vm = tasksVM

        taskListContent()
            .navigationTitle(statusFilter.label)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $vm.searchText, prompt: "Filter")
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
                    Button("Add Task", systemImage: "plus") {
                        preselectedTorrent = nil
                        appViewModel.prefilledAddTaskURL = nil
                        appViewModel.isShowingAddTask = true
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
                title: "No Tasks",
                systemImage: "checklist",
                description: "Add a new download task using the + button."
            )
            .errorAlert(isPresented: $vm.showingError, error: tasksVM.currentError)
            .onChange(of: appViewModel.incomingTorrentURL) { _, newValue in
                guard let url = newValue else { return }
                Task { await importTorrent(from: url) }
            }
            .sheet(isPresented: $localIsShowingAddTask, onDismiss: {
                preselectedTorrent = nil
            }) { addTaskSheet() }
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
        let securityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if securityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let attachment = AddTaskPreselectedTorrent(name: url.lastPathComponent, data: data)

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
