import XCTest
@testable import DSGetCore

// MARK: - Mocks

final class MockNetworkClient: NetworkClientProtocol, @unchecked Sendable {
    var getResult: Result<(Data, HTTPURLResponse), Error> = .failure(NetworkError.invalidURL)
    var postResult: Result<(Data, HTTPURLResponse), Error> = .failure(NetworkError.invalidURL)
    var postMultipartResult: Result<(Data, HTTPURLResponse), Error> = .failure(NetworkError.invalidURL)
    var downloadResult: Result<(Data, HTTPURLResponse), Error> = .failure(NetworkError.invalidURL)

    var getCalled = false
    var postCalled = false
    var lastGetURL: URL?
    var lastGetQueryItems: [URLQueryItem]?

    func get(url: URL, queryItems: [URLQueryItem]) async throws -> (Data, HTTPURLResponse) {
        getCalled = true
        lastGetURL = url
        lastGetQueryItems = queryItems
        return try getResult.get()
    }

    func post(url: URL, queryItems: [URLQueryItem], body: [String: String]) async throws -> (Data, HTTPURLResponse) {
        postCalled = true
        return try postResult.get()
    }

    func postMultipart(url: URL, queryItems: [URLQueryItem], multipartData: MultipartFormData) async throws -> (Data, HTTPURLResponse) {
        return try postMultipartResult.get()
    }

    func downloadWithProgress(url: URL, queryItems: [URLQueryItem], progress: DownloadProgressCallback?) async throws -> (Data, HTTPURLResponse) {
        return try downloadResult.get()
    }
}

final class MockSecureStorage: SecureStorageProtocol, @unchecked Sendable {
    var storage: [String: Data] = [:]
    var saveCalled = false
    var loadCalled = false
    var deleteCalled = false
    var lastSavedKey: String?
    var shouldThrowOnLoad = false
    var shouldThrowOnSave = false

    func save<T: Encodable>(_ item: T, forKey key: String) throws {
        saveCalled = true
        lastSavedKey = key
        if shouldThrowOnSave { throw KeychainError.unexpectedStatus(-1) }
        storage[key] = try JSONEncoder().encode(item)
    }

    func load<T: Decodable>(forKey key: String, type: T.Type) throws -> T {
        loadCalled = true
        if shouldThrowOnLoad { throw KeychainError.itemNotFound }
        guard let data = storage[key] else { throw KeychainError.itemNotFound }
        return try JSONDecoder().decode(T.self, from: data)
    }

    func delete(forKey key: String) throws {
        deleteCalled = true
        storage.removeValue(forKey: key)
    }

    func exists(forKey key: String) -> Bool {
        storage[key] != nil
    }
}

// MARK: - Tests

final class AuthServiceTests: XCTestCase {

    private var networkClient: MockNetworkClient!
    private var secureStorage: MockSecureStorage!
    private var apiClient: SynologyAPIClient!
    private var userDefaults: UserDefaults!
    private var sut: AuthService!

    override func setUp() {
        super.setUp()
        networkClient = MockNetworkClient()
        secureStorage = MockSecureStorage()
        apiClient = SynologyAPIClient(networkClient: networkClient)
        userDefaults = UserDefaults(suiteName: "AuthServiceTests")!
        userDefaults.removePersistentDomain(forName: "AuthServiceTests")

        sut = AuthService(
            apiClient: apiClient,
            networkClient: networkClient,
            secureStorage: secureStorage,
            userDefaults: userDefaults
        )
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "AuthServiceTests")
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeLoginRequest() -> LoginRequest {
        LoginRequest(
            configuration: ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true),
            credentials: Credentials(username: "admin", password: "password123")
        )
    }

    private func makeSuccessLoginResponse() -> Data {
        """
        {"data":{"sid":"test_session_id"},"success":true}
        """.data(using: .utf8)!
    }

    private func makeHTTPResponse(statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://nas.local")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Login Tests

    func testLoginSuccess() async throws {
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))

        let session = try await sut.login(request: makeLoginRequest())

        XCTAssertEqual(session.sessionID, "test_session_id")
        XCTAssertEqual(session.serverConfiguration.host, "nas.local")
        XCTAssertEqual(session.serverConfiguration.port, 5001)
        XCTAssertTrue(session.serverConfiguration.useHTTPS)
    }

    func testLoginStoresSessionInKeychain() async throws {
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))

        _ = try await sut.login(request: makeLoginRequest())

        XCTAssertTrue(secureStorage.saveCalled)
        XCTAssertTrue(secureStorage.exists(forKey: "DSGet.Session"))
        XCTAssertTrue(secureStorage.exists(forKey: "DSGet.Credentials"))
    }

    func testLoginStoresCredentials() async throws {
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))

        _ = try await sut.login(request: makeLoginRequest())

        XCTAssertTrue(secureStorage.exists(forKey: "DSGet.Credentials"))
    }

    func testLoginWithOTPRequired() async throws {
        let response = """
        {"success":false,"error":{"code":403}}
        """.data(using: .utf8)!
        networkClient.getResult = .success((response, makeHTTPResponse()))

        do {
            _ = try await sut.login(request: makeLoginRequest())
            XCTFail("Should throw otpRequired")
        } catch let error as DomainError {
            XCTAssertEqual(error, .otpRequired)
        }
    }

    func testLoginWithInvalidOTP() async throws {
        let response = """
        {"success":false,"error":{"code":404}}
        """.data(using: .utf8)!
        networkClient.getResult = .success((response, makeHTTPResponse()))

        do {
            _ = try await sut.login(request: makeLoginRequest())
            XCTFail("Should throw otpInvalid")
        } catch let error as DomainError {
            XCTAssertEqual(error, .otpInvalid)
        }
    }

    func testLoginWithInvalidCredentials() async throws {
        let response = """
        {"success":true}
        """.data(using: .utf8)!
        networkClient.getResult = .success((response, makeHTTPResponse()))

        do {
            _ = try await sut.login(request: makeLoginRequest())
            XCTFail("Should throw invalidCredentials")
        } catch let error as DomainError {
            XCTAssertEqual(error, .invalidCredentials)
        }
    }

    func testLoginWithInvalidServerConfiguration() async throws {
        let request = LoginRequest(
            configuration: ServerConfiguration(host: "", port: 5001, useHTTPS: true),
            credentials: Credentials(username: "admin", password: "pass")
        )

        do {
            _ = try await sut.login(request: request)
            XCTFail("Should throw")
        } catch let error as DomainError {
            XCTAssertEqual(error, .invalidServerConfiguration)
        }
    }

    func testLoginSendsOTPWhenProvided() async throws {
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))
        let request = LoginRequest(
            configuration: ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true),
            credentials: Credentials(username: "admin", password: "pass", otpCode: "123456")
        )

        _ = try await sut.login(request: request)

        let queryItems = networkClient.lastGetQueryItems ?? []
        XCTAssertTrue(queryItems.contains(where: { $0.name == "otp_code" && $0.value == "123456" }))
    }

    // MARK: - Logout Tests

    func testLogoutClearsStorage() async throws {
        // First login
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))
        _ = try await sut.login(request: makeLoginRequest())

        // Then logout
        try await sut.logout()

        XCTAssertTrue(secureStorage.deleteCalled)
    }

    func testLogoutWhenNotLoggedIn() async throws {
        // Should not throw
        try await sut.logout()
    }

    // MARK: - Session Tests

    func testGetStoredSessionReturnsNilWhenEmpty() async throws {
        let session = try await sut.getStoredSession()
        XCTAssertNil(session)
    }

    func testGetStoredSessionReturnsSessionAfterLogin() async throws {
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))
        _ = try await sut.login(request: makeLoginRequest())

        let session = try await sut.getStoredSession()
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.sessionID, "test_session_id")
    }

    func testGetCurrentSessionReturnsNilWhenEmpty() throws {
        let session = try sut.getCurrentSession()
        XCTAssertNil(session)
    }

    func testIsLoggedInReturnsFalseWhenNotLoggedIn() async {
        let result = await sut.isLoggedIn()
        XCTAssertFalse(result)
    }

    func testIsLoggedInReturnsTrueAfterLogin() async throws {
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))
        _ = try await sut.login(request: makeLoginRequest())

        let result = await sut.isLoggedIn()
        XCTAssertTrue(result)
    }

    func testRefreshSessionThrowsWhenNoStoredSession() async {
        do {
            _ = try await sut.refreshSession()
            XCTFail("Should throw notAuthenticated")
        } catch let error as DomainError {
            XCTAssertEqual(error, .notAuthenticated)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Server Management Tests

    func testGetServerReturnsNilWhenEmpty() async throws {
        let server = try await sut.getServer()
        XCTAssertNil(server)
    }

    func testHasServerReturnsFalseWhenEmpty() async {
        let result = await sut.hasServer()
        XCTAssertFalse(result)
    }

    func testGetCredentialsThrowsWhenNoCredentials() async {
        do {
            _ = try await sut.getCredentials()
            XCTFail("Should throw")
        } catch let error as DomainError {
            if case .serverCredentialsNotFound = error {
                // Expected
            } else {
                XCTFail("Wrong error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRemoveServerClearsData() async throws {
        // Setup: logout should not fail
        networkClient.getResult = .success((makeSuccessLoginResponse(), makeHTTPResponse()))

        try await sut.removeServer()

        let server = try await sut.getServer()
        XCTAssertNil(server)
    }
}
