import Foundation

/// Task service implementation for download operations.
public final class TaskService: TaskServiceProtocol, @unchecked Sendable {
    private let apiClient: any SynologyAPIClientProtocol
    private let connectivityService: ConnectivityServiceProtocol
    private let mapper: TaskMapper

    public init(
        apiClient: any SynologyAPIClientProtocol,
        connectivityService: ConnectivityServiceProtocol,
        mapper: TaskMapper = TaskMapper()
    ) {
        self.apiClient = apiClient
        self.connectivityService = connectivityService
        self.mapper = mapper
    }

    // MARK: - TaskServiceProtocol

    public func getTasks(forceRefresh: Bool) async throws -> TasksResult {
        // Check connectivity
        if !connectivityService.isConnected {
            throw DomainError.noConnection
        }

        // Fetch from API
        let response: SynoResponseDTO<TaskListResponseDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "list",
            version: 1,
            params: ["additional": "detail,transfer,file,tracker"]
        )

        let dto = response.data ?? TaskListResponseDTO(tasks: [])
        let tasks = mapper.mapToEntities(dto.tasks)

        return TasksResult(tasks: tasks, isFromCache: false)
    }

    public func createTask(request: CreateTaskRequest) async throws {
        switch request {
        case let .url(url, destination):
            try await createTaskFromURL(url.absoluteString, destination: destination)

        case let .magnetLink(magnetLink, destination):
            try await createTaskFromURL(magnetLink, destination: destination)

        case let .torrentFile(data, fileName, destination):
            try await createTaskFromTorrent(data: data, fileName: fileName, destination: destination)
        }
    }

    public func pauseTasks(ids: [TaskID]) async throws {
        try await performTaskAction(method: "pause", ids: ids)
    }

    public func resumeTasks(ids: [TaskID]) async throws {
        try await performTaskAction(method: "resume", ids: ids)
    }

    public func deleteTasks(ids: [TaskID]) async throws {
        try await performTaskAction(method: "delete", ids: ids)
    }

    public func editTaskDestination(ids: [TaskID], destination: String) async throws {
        let idsParam = ids.map { $0.rawValue }.joined(separator: ",")

        let response: SynoResponseDTO<[TaskEditResultDTO]> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "edit",
            version: 1,
            params: ["id": idsParam, "destination": destination]
        )

        try checkTaskActionResults(response.data ?? [], action: "edit destination")
    }

    // MARK: - Private Methods

    private func performTaskAction(method: String, ids: [TaskID]) async throws {
        let idsParam = ids.map { $0.rawValue }.joined(separator: ",")

        let response: SynoResponseDTO<[TaskActionResultDTO]> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: method,
            version: 1,
            params: ["id": idsParam]
        )

        try checkTaskActionResults(response.data ?? [], action: method)
    }

    private func checkTaskActionResults(_ results: [TaskActionResultDTO], action: String) throws {
        if let firstError = results.first(where: { $0.error != 0 }) {
            let errorID = TaskID(firstError.id)
            throw DomainError.taskOperationFailed(errorID, reason: "Failed to \(action) task (error: \(firstError.error))")
        }
    }

    private func createTaskFromURL(_ uri: String, destination: String?) async throws {
        // Use GET request with version 1, matching the CLI implementation
        var params: [String: String] = ["uri": uri]
        if let dest = destination {
            params["destination"] = dest
        }

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "create",
            version: 1,
            params: params
        )
    }

    private func createTaskFromTorrent(data: Data, fileName: String, destination: String?) async throws {
        var params: [String: String] = [:]
        if let dest = destination {
            params["destination"] = dest
        }

        let file = FileUpload(data: data, fileName: fileName, mimeType: "application/x-bittorrent")
        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.postMultipart(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "create",
            version: 3,
            params: params,
            file: file
        )
    }
}
