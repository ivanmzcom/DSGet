//
//  TaskFilterMenus.swift
//  DSGet
//

import SwiftUI
import DSGetCore

struct TaskFilterMenu: View {
    let viewModel: TasksViewModel
    let statusFilter: TaskStatusFilter
    let onStatusFilterChange: ((TaskStatusFilter) -> Void)?

    private var hasActiveFilters: Bool {
        statusFilter != .all || viewModel.taskTypeFilter != .all
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Menu {
            if let onStatusFilterChange {
                Section(String.localized("tasks.filter.status")) {
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
                }
            }

            Section(String.localized("tasks.type.filter")) {
                Picker(String.localized("tasks.type.filter"), selection: $viewModel.taskTypeFilter) {
                    ForEach(TaskTypeFilter.allCases) { type in
                        Text(type.localizedShortLabel).tag(type)
                    }
                }
            }

            if !viewModel.searchText.isEmpty {
                Button(String.localized("tasks.search.clear"), systemImage: "xmark.circle") {
                    viewModel.searchText = ""
                }
            }
        } label: {
            Label(
                String.localized("tasks.filters"),
                systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"
            )
        }
    }
}

struct TaskStatusFilterMenu: View {
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
            Label(statusFilter.localizedLabel, systemImage: "line.3.horizontal.decrease.circle")
        }
    }
}

struct TaskTypeFilterMenu: View {
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

struct TaskSortMenu: View {
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

extension TaskStatusFilter {
    var localizedLabel: String {
        switch self {
        case .all: String.localized("tasks.filter.all")
        case .downloading: String.localized("tasks.filter.downloading")
        case .paused: String.localized("tasks.filter.paused")
        case .completed: String.localized("tasks.filter.completed")
        }
    }
}

extension TaskTypeFilter {
    var localizedShortLabel: String {
        switch self {
        case .all: String.localized("tasks.type.all")
        case .bt: String.localized("tasks.type.bt")
        case .e2k: String.localized("tasks.type.e2k")
        }
    }
}

extension TaskSortKey {
    var localizedLabel: String {
        switch self {
        case .date: String.localized("tasks.sort.date")
        case .name: String.localized("tasks.sort.name")
        case .downloadSpeed: String.localized("tasks.sort.downloadSpeed")
        case .uploadSpeed: String.localized("tasks.sort.uploadSpeed")
        }
    }
}

extension TaskSortDirection {
    var localizedLabel: String {
        switch self {
        case .ascending: String.localized("tasks.sort.ascending")
        case .descending: String.localized("tasks.sort.descending")
        }
    }
}
