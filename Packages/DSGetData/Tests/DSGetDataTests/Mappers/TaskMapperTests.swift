import XCTest
@testable import DSGetData
@testable import DSGetDomain

final class TaskMapperTests: XCTestCase {

    var mapper: TaskMapper!

    override func setUp() {
        mapper = TaskMapper()
    }

    // MARK: - Basic Mapping Tests

    func testMapToEntityBasic() {
        // Given
        let dto = DownloadTaskDTO(
            id: "task-123",
            title: "Test Download",
            size: 1024 * 1024 * 100, // 100 MB
            status: "downloading",
            type: "bt",
            username: "admin",
            additional: nil
        )

        // When
        let entity = mapper.mapToEntity(dto)

        // Then
        XCTAssertEqual(entity.id.rawValue, "task-123")
        XCTAssertEqual(entity.title, "Test Download")
        XCTAssertEqual(entity.size.bytes, 1024 * 1024 * 100)
        XCTAssertEqual(entity.status, .downloading)
        XCTAssertEqual(entity.type, .bt)
        XCTAssertEqual(entity.username, "admin")
    }

    func testMapToEntityWithAdditional() {
        // Given
        let transfer = TaskTransferDTO(
            sizeDownloaded: 50 * 1024 * 1024, // 50 MB
            sizeUploaded: 10 * 1024 * 1024,
            speedDownload: 1024 * 100, // 100 KB/s
            speedUpload: 1024 * 20
        )

        let detail = TaskDetailDTO(
            completedTime: nil,
            connectedLeechers: 5,
            connectedPeers: 10,
            connectedSeeders: 15,
            createTime: Date().timeIntervalSince1970,
            destination: "/downloads",
            seedelapsed: nil,
            startedTime: Date().timeIntervalSince1970,
            totalPeers: 100,
            totalPieces: 500,
            totalSize: 1024 * 1024 * 100,
            unzipPassword: nil,
            uri: "magnet:?xt=test",
            waitingSeconds: nil
        )

        let additional = TaskAdditionalDTO(
            detail: detail,
            transfer: transfer,
            file: nil,
            tracker: nil
        )

        let dto = DownloadTaskDTO(
            id: "task-456",
            title: "Test with Additional",
            size: 1024 * 1024 * 100,
            status: "downloading",
            type: "bt",
            username: "admin",
            additional: additional
        )

        // When
        let entity = mapper.mapToEntity(dto)

        // Then
        XCTAssertNotNil(entity.transfer)
        XCTAssertEqual(entity.transfer?.downloaded.bytes, 50 * 1024 * 1024)
        XCTAssertEqual(entity.transfer?.downloadSpeed.bytes, 1024 * 100)

        XCTAssertNotNil(entity.detail)
        XCTAssertEqual(entity.detail?.destination, "/downloads")
        XCTAssertEqual(entity.detail?.connectedSeeders, 15)
    }

    // MARK: - Status Mapping Tests

    func testMapAllStatuses() {
        let statuses: [(String, TaskStatus)] = [
            ("downloading", .downloading),
            ("paused", .paused),
            ("seeding", .seeding),
            ("finished", .finished),
            ("waiting", .waiting),
            ("error", .error),
            ("hash_checking", .hashChecking),
            ("extracting", .extracting)
        ]

        for (apiValue, expected) in statuses {
            let dto = DownloadTaskDTO(
                id: "task",
                title: "Test",
                size: 100,
                status: apiValue,
                type: "bt",
                username: "admin"
            )
            let entity = mapper.mapToEntity(dto)
            XCTAssertEqual(entity.status, expected, "Failed for status: \(apiValue)")
        }
    }

    // MARK: - Type Mapping Tests

    func testMapAllTypes() {
        let types: [(String, TaskType)] = [
            ("bt", .bt),
            ("http", .http),
            ("ftp", .ftp),
            ("nzb", .nzb),
            ("emule", .emule)
        ]

        for (apiValue, expected) in types {
            let dto = DownloadTaskDTO(
                id: "task",
                title: "Test",
                size: 100,
                status: "downloading",
                type: apiValue,
                username: "admin"
            )
            let entity = mapper.mapToEntity(dto)
            XCTAssertEqual(entity.type, expected, "Failed for type: \(apiValue)")
        }
    }

    // MARK: - List Mapping Tests

    func testMapToEntities() {
        // Given
        let dtos = [
            DownloadTaskDTO(id: "1", title: "Task 1", size: 100, status: "downloading", type: "bt", username: "admin"),
            DownloadTaskDTO(id: "2", title: "Task 2", size: 200, status: "paused", type: "http", username: "admin"),
            DownloadTaskDTO(id: "3", title: "Task 3", size: 300, status: "finished", type: "ftp", username: "admin")
        ]

        // When
        let entities = mapper.mapToEntities(dtos)

        // Then
        XCTAssertEqual(entities.count, 3)
        XCTAssertEqual(entities[0].id.rawValue, "1")
        XCTAssertEqual(entities[1].id.rawValue, "2")
        XCTAssertEqual(entities[2].id.rawValue, "3")
    }
}
