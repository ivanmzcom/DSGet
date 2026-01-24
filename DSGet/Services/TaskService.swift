import Foundation

/// Task service implementation for download operations.
final class TaskService: TaskServiceProtocol, @unchecked Sendable {

    private let apiClient: SynologyAPIClient
    private let connectivityService: ConnectivityServiceProtocol
    private let mapper: TaskMapper

    init(
        apiClient: SynologyAPIClient,
        connectivityService: ConnectivityServiceProtocol,
        mapper: TaskMapper = TaskMapper()
    ) {
        self.apiClient = apiClient
        self.connectivityService = connectivityService
        self.mapper = mapper
    }

    // MARK: - TaskServiceProtocol

    func getTasks(forceRefresh: Bool) async throws -> TasksResult {
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

    func createTask(request: CreateTaskRequest) async throws {
        switch request {
        case .url(let url, let destination):
            try await createTaskFromURL(url.absoluteString, destination: destination)
        case .magnetLink(let magnetLink, let destination):
            try await createTaskFromURL(magnetLink, destination: destination)
        case .torrentFile(let data, let fileName, let destination):
            try await createTaskFromTorrent(data: data, fileName: fileName, destination: destination)
        }
    }

    func pauseTasks(ids: [TaskID]) async throws {
        let idsParam = ids.map { $0.rawValue }.joined(separator: ",")

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "pause",
            version: 1,
            params: ["id": idsParam]
        )
    }

    func resumeTasks(ids: [TaskID]) async throws {
        let idsParam = ids.map { $0.rawValue }.joined(separator: ",")

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "resume",
            version: 1,
            params: ["id": idsParam]
        )
    }

    func deleteTasks(ids: [TaskID]) async throws {
        let idsParam = ids.map { $0.rawValue }.joined(separator: ",")

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "delete",
            version: 1,
            params: ["id": idsParam]
        )
    }

    func editTaskDestination(ids: [TaskID], destination: String) async throws {
        let idsParam = ids.map { $0.rawValue }.joined(separator: ",")

        let response: SynoResponseDTO<[TaskEditResultDTO]> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "edit",
            version: 1,
            params: ["id": idsParam, "destination": destination]
        )

        // Check for errors in results
        let results = response.data ?? []
        let errors = results.filter { $0.error != 0 }
        if let firstError = errors.first {
            let errorID = TaskID(firstError.id)
            throw DomainError.taskOperationFailed(errorID, reason: "Failed to edit destination (error: \(firstError.error))")
        }
    }

    // MARK: - Private Methods

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

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.postMultipart(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "create",
            version: 3,
            params: params,
            fileData: data,
            fileName: fileName,
            mimeType: "application/x-bittorrent"
        )
    }
}
