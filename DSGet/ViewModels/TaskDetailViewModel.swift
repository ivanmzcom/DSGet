//
//  TaskDetailViewModel.swift
//  DSGet
//
//  ViewModel for task detail view, handling pause/resume, delete, and edit operations.
//

import Foundation
import SwiftUI
import DSGetCore

// MARK: - TaskDetailViewModel

/// ViewModel that manages the state and logic for task detail view.
@MainActor
@Observable
final class TaskDetailViewModel: DomainErrorHandling {

    // MARK: - Published State

    /// The task being displayed.
    private(set) var task: DownloadTask

    /// Whether an action is being processed.
    private(set) var isProcessingAction: Bool = false

    /// Status override for optimistic UI updates.
    var statusOverride: String?

    /// Current error.
    var currentError: DSGetError?

    /// Whether to show error alert.
    var showingError: Bool = false

    /// Whether to show delete confirmation.
    var showingDeleteConfirmation: Bool = false

    /// Whether to show edit destination sheet.
    var showingEditDestination: Bool = false

    // MARK: - Callbacks

    /// Called when the task is updated.
    var onTaskUpdated: (() -> Void)?

    /// Called when the task is deleted.
    var onTaskDeleted: (() -> Void)?

    // MARK: - Computed Properties

    /// Effective status considering override.
    var effectiveStatus: String {
        statusOverride ?? task.status.apiValue
    }

    /// Whether the task is paused.
    var isTaskPaused: Bool {
        effectiveStatus == "paused"
    }

    /// Whether the task can be paused/resumed.
    var canTogglePause: Bool {
        guard !isProcessingAction else { return false }
        let isEmule = task.type == .emule
        let statusLower = effectiveStatus.lowercased()
        let isCompletedEmule = isEmule && ["finished", "completed", "seeding"].contains(statusLower)
        let allowedStatuses: Set<String> = ["downloading", "paused", "waiting", "seeding"]
        return !isCompletedEmule && allowedStatuses.contains(statusLower)
    }

    // MARK: - Dependencies

    private let taskService: TaskServiceProtocol

    // MARK: - Initialization

    init(
        task: DownloadTask,
        taskService: TaskServiceProtocol? = nil
    ) {
        self.task = task
        self.taskService = taskService ?? DI.taskService
    }

    // MARK: - Public Methods

    /// Updates the task with new data.
    func updateTask(_ task: DownloadTask) {
        self.task = task
        statusOverride = nil
    }

    /// Toggles between pause and resume state.
    func togglePauseResume() async {
        guard canTogglePause else { return }

        isProcessingAction = true
        currentError = nil
        showingError = false

        do {
            if isTaskPaused {
                try await taskService.resumeTasks(ids: [task.id])
                statusOverride = "downloading"
            } else {
                try await taskService.pauseTasks(ids: [task.id])
                statusOverride = "paused"
            }
            onTaskUpdated?()
        } catch {
            handleError(error)
        }

        isProcessingAction = false
    }

    /// Deletes the task.
    func deleteTask() async {
        isProcessingAction = true
        currentError = nil
        showingError = false

        do {
            try await taskService.deleteTasks(ids: [task.id])
            onTaskUpdated?()
            onTaskDeleted?()
        } catch {
            handleError(error)
        }

        isProcessingAction = false
    }

    /// Edits the task destination.
    func editDestination(_ destination: String) async {
        isProcessingAction = true
        currentError = nil
        showingError = false

        do {
            try await taskService.editTaskDestination(ids: [task.id], destination: destination)
            onTaskUpdated?()
        } catch {
            handleError(error)
        }

        isProcessingAction = false
    }
}
