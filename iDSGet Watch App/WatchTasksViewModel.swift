//
//  WatchTasksViewModel.swift
//  iDSGet Watch App
//
//  ViewModel for managing download tasks on watchOS.
//

import Foundation
import DSGetCore

@MainActor
@Observable
final class WatchTasksViewModel {

    // MARK: - State

    private(set) var tasks: [DownloadTask] = []
    private(set) var isLoading: Bool = false
    private(set) var error: DSGetError?

    // MARK: - Dependencies

    private let taskService: TaskServiceProtocol
    private let authService: AuthServiceProtocol

    // MARK: - Initialization

    init(
        taskService: TaskServiceProtocol? = nil,
        authService: AuthServiceProtocol? = nil
    ) {
        self.taskService = taskService ?? WatchDI.taskService
        self.authService = authService ?? WatchDI.authService
    }

    // MARK: - Public Methods

    func loadTasks() async {
        guard !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            // First validate session
            _ = try await authService.validateSession()

            // Then fetch tasks
            let result = try await taskService.getTasks(forceRefresh: false)
            tasks = result.tasks.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            error = nil
        } catch {
            self.error = DSGetError.from(error)
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await taskService.getTasks(forceRefresh: true)
            tasks = result.tasks.sorted { ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast) }
            error = nil
        } catch {
            self.error = DSGetError.from(error)
        }
    }
}
