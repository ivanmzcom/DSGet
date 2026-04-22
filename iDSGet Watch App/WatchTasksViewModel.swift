import Foundation
import DSGetCore

@MainActor
@Observable
final class WatchTasksViewModel {
    enum Phase: Equatable {
        case checkingSession
        case waitingForPhone
        case ready
    }

    private(set) var phase: Phase = .checkingSession
    private(set) var tasks: [DownloadTask] = []
    private(set) var isLoading: Bool = false
    private(set) var error: DSGetError?
    private(set) var serverName: String?
    private(set) var lastUpdatedAt: Date?

    private let taskService: TaskServiceProtocol
    private let authService: AuthServiceProtocol
    private let syncService: WatchCompanionSyncService

    init(
        taskService: TaskServiceProtocol? = nil,
        authService: AuthServiceProtocol? = nil,
        syncService: WatchCompanionSyncService? = nil
    ) {
        self.taskService = taskService ?? WatchDI.taskService
        self.authService = authService ?? WatchDI.authService
        self.syncService = syncService ?? .shared
        self.syncService.onAuthenticationDidChange = { [weak self] in
            await self?.bootstrap()
        }
    }

    var navigationTitle: String {
        switch phase {
        case .checkingSession:
            return String.watchLocalized("watch.app.title")
        case .waitingForPhone:
            return String.watchLocalized("watch.waiting.title")
        case .ready:
            return String.watchLocalized("watch.downloads_title")
        }
    }

    var activeTasksCount: Int {
        tasks.filter { $0.status.isActive || $0.status == .waiting }.count
    }

    var completedTasksCount: Int {
        tasks.filter(\.isCompleted).count
    }

    var totalDownloadSpeed: String {
        tasks.reduce(.zero) { $0 + $1.downloadSpeed }.formattedAsSpeed
    }

    func bootstrap() async {
        isLoading = true
        phase = .checkingSession
        syncService.activate()
        await loadServerName()

        do {
            if let _ = try await authService.validateSession() {
                phase = .ready
                await fetchTasks(forceRefresh: false)
            } else {
                tasks = []
                phase = .waitingForPhone
                isLoading = false
                syncService.requestAuthenticationSync()
            }
        } catch {
            self.error = DSGetError.from(error)
            tasks = []
            phase = .waitingForPhone
            isLoading = false
            syncService.requestAuthenticationSync()
        }
    }

    func refresh() async {
        guard phase == .ready else { return }
        await fetchTasks(forceRefresh: true)
    }

    func togglePause(_ task: DownloadTask) async {
        guard phase == .ready else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if task.status.canResume {
                try await taskService.resumeTasks(ids: [task.id])
            } else if task.status.canPause {
                try await taskService.pauseTasks(ids: [task.id])
            }

            await fetchTasks(forceRefresh: true, showsLoading: false)
        } catch {
            self.error = DSGetError.from(error)
        }
    }

    func delete(_ task: DownloadTask) async {
        guard phase == .ready else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try await taskService.deleteTasks(ids: [task.id])
            tasks.removeAll { $0.id == task.id }
            lastUpdatedAt = Date()
        } catch {
            self.error = DSGetError.from(error)
        }
    }

    func clearError() {
        error = nil
    }

    private func loadServerName() async {
        serverName = try? await authService.getServer()?.displayName
    }

    var companionStatusText: String {
        switch syncService.state {
        case .idle, .waitingForPhone:
            return String.watchLocalized("watch.waiting.message")
        case .syncing:
            return String.watchLocalized("watch.waiting.syncing")
        case .synced(let date):
            return String.watchLocalized(
                "watch.waiting.syncedAt",
                date.formatted(date: .omitted, time: .shortened)
            )
        case .failed:
            return String.watchLocalized("watch.waiting.retry")
        }
    }

    var canRetrySync: Bool {
        phase == .waitingForPhone
    }

    func retryCompanionSync() {
        syncService.requestAuthenticationSync()
    }

    private func fetchTasks(forceRefresh: Bool, showsLoading: Bool = true) async {
        if showsLoading {
            isLoading = true
        }
        defer { isLoading = false }

        do {
            let result = try await taskService.getTasks(forceRefresh: forceRefresh)
            tasks = result.tasks.sorted {
                ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
            lastUpdatedAt = Date()
            error = nil
        } catch {
            self.error = DSGetError.from(error)
        }
    }
}
