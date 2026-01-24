import XCTest
@testable import DSGetData
@testable import DSGetDomain

/// Integration tests that connect to a real Synology NAS.
/// These tests require environment variables to be set with valid credentials.
/// See TestConfiguration.swift for setup instructions.
final class SynologyAPIIntegrationTests: XCTestCase {

    var networkClient: NetworkClient!
    var authDataSource: SynologyAuthDataSource!
    var apiClient: SynologyAPIClient!

    override func setUp() async throws {
        guard TestConfiguration.shared.isConfigured else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        networkClient = NetworkClient.shared
        authDataSource = SynologyAuthDataSource(networkClient: networkClient)
        apiClient = SynologyAPIClient(networkClient: networkClient)
    }

    // MARK: - Authentication Tests

    func testLoginWithValidCredentials() async throws {
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let baseURL = config.baseURL,
              let credentials = TestConfiguration.shared.getCredentials() else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        // When
        let response = try await authDataSource.login(
            baseURL: baseURL,
            username: credentials.username,
            password: credentials.password,
            otpCode: nil
        )

        // Then
        XCTAssertNotNil(response.sid, "Session ID should not be nil")
        if let sid = response.sid {
            XCTAssertFalse(sid.isEmpty, "Session ID should not be empty")
            // Cleanup - logout
            try? await authDataSource.logout(baseURL: baseURL, sessionID: sid)
        }
    }

    func testLoginWithInvalidCredentials() async throws {
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let baseURL = config.baseURL else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        // When/Then
        do {
            _ = try await authDataSource.login(
                baseURL: baseURL,
                username: "invaliduser",
                password: "invalidpassword",
                otpCode: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - invalid credentials should throw an error
            XCTAssertTrue(true)
        }
    }

    func testLogout() async throws {
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let baseURL = config.baseURL,
              let credentials = TestConfiguration.shared.getCredentials() else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        // Given - login first
        let loginResponse = try await authDataSource.login(
            baseURL: baseURL,
            username: credentials.username,
            password: credentials.password,
            otpCode: nil
        )

        guard let sid = loginResponse.sid else {
            XCTFail("Login should return a session ID")
            return
        }

        // When
        try await authDataSource.logout(baseURL: baseURL, sessionID: sid)

        // Then - session should be invalidated (no error thrown means success)
        XCTAssertTrue(true)
    }

    // MARK: - API Info Tests

    func testGetAPIInfo() async throws {
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let baseURL = config.baseURL,
              let credentials = TestConfiguration.shared.getCredentials() else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        // Login first
        let loginResponse = try await authDataSource.login(
            baseURL: baseURL,
            username: credentials.username,
            password: credentials.password,
            otpCode: nil
        )

        guard let sid = loginResponse.sid else {
            XCTFail("Login should return a session ID")
            return
        }

        // Configure the API client
        await apiClient.configure(serverConfig: config, sessionID: sid)

        // Cleanup
        try? await authDataSource.logout(baseURL: baseURL, sessionID: sid)
    }
}

// MARK: - Download Station Integration Tests

final class DownloadStationIntegrationTests: XCTestCase {

    var networkClient: NetworkClient!
    var authDataSource: SynologyAuthDataSource!
    var apiClient: SynologyAPIClient!
    var taskDataSource: SynologyTaskDataSource!
    var sessionID: String?
    var baseURL: URL?

    override func setUp() async throws {
        guard TestConfiguration.shared.isConfigured else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        networkClient = NetworkClient.shared
        authDataSource = SynologyAuthDataSource(networkClient: networkClient)
        apiClient = SynologyAPIClient(networkClient: networkClient)
        taskDataSource = SynologyTaskDataSource(apiClient: apiClient)

        // Login
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let url = config.baseURL,
              let credentials = TestConfiguration.shared.getCredentials() else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        baseURL = url

        let response = try await authDataSource.login(
            baseURL: url,
            username: credentials.username,
            password: credentials.password,
            otpCode: nil
        )

        sessionID = response.sid
        await apiClient.configure(serverConfig: config, sessionID: response.sid)
    }

    override func tearDown() async throws {
        // Logout
        if let sid = sessionID, let url = baseURL {
            try? await authDataSource.logout(baseURL: url, sessionID: sid)
        }
    }

    func testGetTasks() async throws {
        // When
        let tasksResponse = try await taskDataSource.fetchTasks(additional: ["detail", "transfer"])

        // Then
        // Just verify we got a response (even if empty)
        XCTAssertNotNil(tasksResponse.tasks)
    }

    func testGetTasksWithAdditionalInfo() async throws {
        // When
        let tasksResponse = try await taskDataSource.fetchTasks(additional: ["detail", "transfer"])

        // Then
        for task in tasksResponse.tasks {
            // Verify basic fields are present
            XCTAssertFalse(task.id.isEmpty)
            XCTAssertFalse(task.title.isEmpty)
        }
    }
}

// MARK: - File Station Integration Tests

final class FileStationIntegrationTests: XCTestCase {

    var networkClient: NetworkClient!
    var authDataSource: SynologyAuthDataSource!
    var apiClient: SynologyAPIClient!
    var fileDataSource: SynologyFileDataSource!
    var sessionID: String?
    var baseURL: URL?

    override func setUp() async throws {
        guard TestConfiguration.shared.isConfigured else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        networkClient = NetworkClient.shared
        authDataSource = SynologyAuthDataSource(networkClient: networkClient)
        apiClient = SynologyAPIClient(networkClient: networkClient)
        fileDataSource = SynologyFileDataSource(apiClient: apiClient)

        // Login
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let url = config.baseURL,
              let credentials = TestConfiguration.shared.getCredentials() else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        baseURL = url

        let response = try await authDataSource.login(
            baseURL: url,
            username: credentials.username,
            password: credentials.password,
            otpCode: nil
        )

        sessionID = response.sid
        await apiClient.configure(serverConfig: config, sessionID: response.sid)
    }

    override func tearDown() async throws {
        if let sid = sessionID, let url = baseURL {
            try? await authDataSource.logout(baseURL: url, sessionID: sid)
        }
    }

    func testGetShares() async throws {
        // When
        let sharesResponse = try await fileDataSource.fetchShares()

        // Then
        XCTAssertNotNil(sharesResponse.shares)
        // Most NAS devices should have at least one share
        XCTAssertFalse(sharesResponse.shares.isEmpty, "Expected at least one shared folder")
    }

    func testGetFolderContents() async throws {
        // First get shares to find a valid path
        let sharesResponse = try await fileDataSource.fetchShares()
        guard let firstShare = sharesResponse.shares.first else {
            throw XCTSkip("No shared folders available for testing")
        }

        // When
        let contents = try await fileDataSource.fetchFolderContents(path: firstShare.path)

        // Then
        XCTAssertNotNil(contents.files)
    }

}

// MARK: - RSS Feed Integration Tests

final class RSSFeedIntegrationTests: XCTestCase {

    var networkClient: NetworkClient!
    var authDataSource: SynologyAuthDataSource!
    var apiClient: SynologyAPIClient!
    var feedDataSource: SynologyFeedDataSource!
    var sessionID: String?
    var baseURL: URL?

    override func setUp() async throws {
        guard TestConfiguration.shared.isConfigured else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        networkClient = NetworkClient.shared
        authDataSource = SynologyAuthDataSource(networkClient: networkClient)
        apiClient = SynologyAPIClient(networkClient: networkClient)
        feedDataSource = SynologyFeedDataSource(apiClient: apiClient)

        // Login
        guard let config = TestConfiguration.shared.getServerConfiguration(),
              let url = config.baseURL,
              let credentials = TestConfiguration.shared.getCredentials() else {
            throw XCTSkip(integrationTestSkipMessage)
        }

        baseURL = url

        let response = try await authDataSource.login(
            baseURL: url,
            username: credentials.username,
            password: credentials.password,
            otpCode: nil
        )

        sessionID = response.sid
        await apiClient.configure(serverConfig: config, sessionID: response.sid)
    }

    override func tearDown() async throws {
        if let sid = sessionID, let url = baseURL {
            try? await authDataSource.logout(baseURL: url, sessionID: sid)
        }
    }

    func testGetFeeds() async throws {
        // When
        let feeds = try await feedDataSource.fetchFeeds(offset: nil, limit: nil)

        // Then
        XCTAssertNotNil(feeds)
        // It's okay if there are no feeds configured
    }
}
