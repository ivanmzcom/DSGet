import Foundation

/// Synology API implementation for task operations.
public final class SynologyTaskDataSource: TaskRemoteDataSource, @unchecked Sendable {

    private let apiClient: SynologyAPIClient

    public init(apiClient: SynologyAPIClient) {
        self.apiClient = apiClient
    }

    public func fetchTasks(additional: [String]) async throws -> TaskListResponseDTO {
        let additionalParam = additional.joined(separator: ",")

        let response: SynoResponseDTO<TaskListResponseDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "list",
            version: 1,
            params: ["additional": additionalParam]
        )

        guard let data = response.data else {
            return TaskListResponseDTO(tasks: [])
        }

        return data
    }

    public func createTask(url: String, destination: String?) async throws {
        var params: [String: String] = ["uri": url]
        if let dest = destination {
            params["destination"] = dest
        }

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.post(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "create",
            version: 3,
            params: params
        )
    }

    public func createTask(torrentData: Data, fileName: String, destination: String?) async throws {
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
            fileData: torrentData,
            fileName: fileName,
            mimeType: "application/x-bittorrent"
        )
    }

    public func pauseTasks(ids: [String]) async throws {
        let idsParam = ids.joined(separator: ",")

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "pause",
            version: 1,
            params: ["id": idsParam]
        )
    }

    public func resumeTasks(ids: [String]) async throws {
        let idsParam = ids.joined(separator: ",")

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "resume",
            version: 1,
            params: ["id": idsParam]
        )
    }

    public func deleteTasks(ids: [String]) async throws {
        let idsParam = ids.joined(separator: ",")

        let _: SynoResponseDTO<EmptyDataDTO> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "delete",
            version: 1,
            params: ["id": idsParam]
        )
    }

    public func editTaskDestination(ids: [String], destination: String) async throws -> [TaskEditResultDTO] {
        let idsParam = ids.joined(separator: ",")

        let response: SynoResponseDTO<[TaskEditResultDTO]> = try await apiClient.get(
            endpoint: .downloadStation,
            api: "SYNO.DownloadStation.Task",
            method: "edit",
            version: 1,
            params: ["id": idsParam, "destination": destination]
        )

        return response.data ?? []
    }
}
