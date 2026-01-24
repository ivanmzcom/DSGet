//
//  TasksViewModel.swift
//  DSGet
//
//  Centralized ViewModel for download task management.
//

import Foundation
import SwiftUI
import FactoryKit

// MARK: - TasksViewModel

/// ViewModel that centralizes state and logic for download tasks.
@MainActor
@Observable
final class TasksViewModel: DomainErrorHandling, OfflineModeSupporting {

    // MARK: - Published State

    /// Complete list of tasks.
    private(set) var tasks: [DownloadTask] = []

    /// Currently selected task.
    var selectedTask: DownloadTask?

    /// Indicates if data is loading.
    private(set) var isLoading: Bool = false

    /// Indicates if in offline mode (showing cached data).
    var isOfflineMode: Bool = false

    /// Active downloads counter.
    private(set) var activeDownloadCount: Int = 0

    /// Current error if any.
    var currentError: DSGetError?

    /// Indicates if error alert should be shown.
    var showingError: Bool = false

    // MARK: - Filter State

    /// Current status filter.
    var statusFilter: TaskStatusFilter = .all

    /// Task type filter.
    var taskTypeFilter: TaskTypeFilter = .all

    /// Search text.
    var searchText: String = ""

    /// Sort key.
    var sortKey: TaskSortKey = .date

    /// Sort direction.
    var sortDirection: TaskSortDirection = .descending

    // MARK: - Computed Properties

    /// Visible tasks after applying filters.
    var visibleTasks: [DownloadTask] {
        var filtered = tasks

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by task type
        filtered = filtered.filter { matchesType($0) }

        // Filter by status
        filtered = filtered.filter { matchesStatus($0) }

        // Sort
        filtered.sort(by: compareTasks(_:_:))

        return filtered
    }

    // MARK: - Injected Dependencies

    private let taskService: TaskServiceProtocol

    // MARK: - Auto-refresh

    private var refreshTimer: Timer?
    private let autoRefreshInterval: TimeInterval = 15.0

    // MARK: - Initialization

    init(taskService: TaskServiceProtocol? = nil) {
        self.taskService = taskService ?? DI.taskService
    }

    // MARK: - Public Methods

    /// Fetches tasks from server or cache.
    func fetchTasks(forceRefresh: Bool = false) async {
        isLoading = true
        currentError = nil
        showingError = false

        do {
            let result = try await taskService.getTasks(forceRefresh: forceRefresh)

            tasks = result.tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            isOfflineMode = result.isFromCache
            updateCounts()

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Refreshes tasks invalidating the cache.
    func refresh() async {
        await fetchTasks(forceRefresh: true)
    }

    /// Starts auto-refresh every 15 seconds.
    func startAutoRefresh() {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: autoRefreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.fetchTasks(forceRefresh: true)
            }
        }
    }

    /// Stops auto-refresh.
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    /// Toggles pause/resume for a task.
    func togglePause(_ task: DownloadTask) async {
        isLoading = true
        currentError = nil

        do {
            if task.status.canResume {
                try await taskService.resumeTasks(ids: [task.id])
            } else if task.status.canPause {
                try await taskService.pauseTasks(ids: [task.id])
            }
            await fetchTasks(forceRefresh: true)
        } catch {
            handleError(error)
            isLoading = false
        }
    }

    /// Deletes a task.
    func deleteTask(_ task: DownloadTask) async {
        isLoading = true
        currentError = nil

        do {
            try await taskService.deleteTasks(ids: [task.id])

            tasks.removeAll { $0.id == task.id }
            if selectedTask?.id == task.id {
                selectedTask = nil
            }
            updateCounts()

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Creates a new task from a URL.
    func createTask(url: String, destination: String?) async throws {
        guard let parsedURL = URL(string: url) else {
            throw DomainError.invalidDownloadURL
        }
        let request: CreateTaskRequest
        if url.lowercased().hasPrefix("magnet:") {
            request = .magnetLink(url, destination: destination)
        } else {
            request = .url(parsedURL, destination: destination)
        }
        try await taskService.createTask(request: request)
        await fetchTasks(forceRefresh: true)
    }

    /// Creates a new task from a torrent file.
    func createTask(fileData: Data, fileName: String, destination: String?) async throws {
        let request = CreateTaskRequest.torrentFile(data: fileData, fileName: fileName, destination: destination)
        try await taskService.createTask(request: request)
        await fetchTasks(forceRefresh: true)
    }

    /// Clears all filters.
    func clearAllFilters() {
        searchText = ""
        taskTypeFilter = .all
        statusFilter = .all
    }

    // MARK: - Private Methods

    private func updateCounts() {
        activeDownloadCount = tasks.filter { $0.isDownloading }.count
    }

    private func matchesType(_ task: DownloadTask) -> Bool {
        switch taskTypeFilter {
        case .all:
            return true
        case .bt:
            return task.type == .bt
        case .e2k:
            return task.type == .emule
        }
    }

    private func matchesStatus(_ task: DownloadTask) -> Bool {
        switch statusFilter {
        case .all:
            return true
        case .downloading:
            return task.isDownloading
        case .paused:
            return task.status == .paused
        case .completed:
            return task.isCompleted
        }
    }

    private func compareTasks(_ lhs: DownloadTask, _ rhs: DownloadTask) -> Bool {
        let ascending = sortDirection == .ascending

        switch sortKey {
        case .date:
            let lhsDate = lhs.sortDate ?? .distantPast
            let rhsDate = rhs.sortDate ?? .distantPast
            if lhsDate == rhsDate {
                return compareByName(lhs, rhs, ascending: true)
            }
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case .name:
            return compareByName(lhs, rhs, ascending: ascending)

        case .downloadSpeed:
            let lhsValue = lhs.transfer?.downloadSpeed.bytes ?? 0
            let rhsValue = rhs.transfer?.downloadSpeed.bytes ?? 0
            if lhsValue == rhsValue {
                return compareByName(lhs, rhs, ascending: true)
            }
            return ascending ? lhsValue < rhsValue : lhsValue > rhsValue

        case .uploadSpeed:
            let lhsValue = lhs.transfer?.uploadSpeed.bytes ?? 0
            let rhsValue = rhs.transfer?.uploadSpeed.bytes ?? 0
            if lhsValue == rhsValue {
                return compareByName(lhs, rhs, ascending: true)
            }
            return ascending ? lhsValue < rhsValue : lhsValue > rhsValue
        }
    }

    private func compareByName(_ lhs: DownloadTask, _ rhs: DownloadTask, ascending: Bool) -> Bool {
        let comparison = lhs.title.localizedCaseInsensitiveCompare(rhs.title)
        if comparison == .orderedSame {
            return ascending ? lhs.id.rawValue < rhs.id.rawValue : lhs.id.rawValue > rhs.id.rawValue
        }
        return ascending ? comparison != .orderedDescending : comparison == .orderedDescending
    }
}
