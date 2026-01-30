import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class AppViewModelTests: XCTestCase {

    private var mockAuthService: MockAuthService!
    private var mockConnectivity: MockConnectivityService!
    private var mockTaskService: MockTaskService!
    private var mockFeedService: MockFeedService!
    private var sut: AppViewModel!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        mockConnectivity = MockConnectivityService()
        mockTaskService = MockTaskService()
        mockFeedService = MockFeedService()
    }

    // MARK: - Helpers

    private func makeSUT() -> AppViewModel {
        let tasksVM = TasksViewModel(taskService: mockTaskService, widgetSyncService: MockWidgetDataSyncService())
        let feedsVM = FeedsViewModel(feedService: mockFeedService)
        return AppViewModel(
            tasksViewModel: tasksVM,
            feedsViewModel: feedsVM,
            authService: mockAuthService,
            connectivityService: mockConnectivity
        )
    }

    private func makeSession() -> Session {
        Session(
            sessionID: "test_sid",
            serverConfiguration: ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        )
    }

    // MARK: - Check Login Status

    func testCheckLoginStatusLoggedIn() async {
        sut = makeSUT()
        mockAuthService.validateSessionResult = makeSession()

        await sut.checkLoginStatus()

        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertFalse(sut.isCheckingAuth)
    }

    func testCheckLoginStatusNotLoggedIn() async {
        sut = makeSUT()
        mockAuthService.validateSessionResult = nil

        await sut.checkLoginStatus()

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertFalse(sut.isCheckingAuth)
    }

    // MARK: - Logout

    func testLogout() async {
        sut = makeSUT()
        sut.isLoggedIn = true

        await sut.logout()

        XCTAssertTrue(mockAuthService.logoutCalled)
        XCTAssertTrue(mockAuthService.removeServerCalled)
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.currentServer)
    }

    // MARK: - Online Status

    func testUpdateOnlineStatusConnected() async {
        sut = makeSUT()
        mockConnectivity.isConnected = true

        await sut.updateOnlineStatus()

        XCTAssertTrue(sut.isOnline)
    }

    func testUpdateOnlineStatusDisconnected() async {
        sut = makeSUT()
        mockConnectivity.isConnected = false

        await sut.updateOnlineStatus()

        XCTAssertFalse(sut.isOnline)
    }

    // MARK: - Load Server

    func testLoadServer() async {
        sut = makeSUT()
        let server = Server.create(name: "My NAS", host: "nas.local", port: 5001, useHTTPS: true)
        mockAuthService.getServerResult = server

        await sut.loadServer()

        XCTAssertNotNil(sut.currentServer)
        XCTAssertEqual(sut.serverName, server.displayName)
    }

    func testLoadServerNil() async {
        sut = makeSUT()
        mockAuthService.getServerResult = nil

        await sut.loadServer()

        XCTAssertNil(sut.currentServer)
        XCTAssertNil(sut.serverName)
    }

    // MARK: - Handle Incoming URL

    func testHandleMagnetURL() {
        sut = makeSUT()
        let url = URL(string: "magnet:?xt=urn:btih:abc123")!

        sut.handleIncomingURL(url)

        XCTAssertNotNil(sut.incomingMagnetURL)
        XCTAssertNil(sut.incomingTorrentURL)
    }

    func testHandleTorrentFileURL() {
        sut = makeSUT()
        let url = URL(fileURLWithPath: "/tmp/test.torrent")

        sut.handleIncomingURL(url)

        XCTAssertNotNil(sut.incomingTorrentURL)
        XCTAssertNil(sut.incomingMagnetURL)
    }

    func testHandleDeepLinkAddURL() {
        sut = makeSUT()
        let url = URL(string: "dsget://add?url=https://example.com/file.zip")!

        sut.handleIncomingURL(url)

        XCTAssertTrue(sut.isShowingAddTask)
        XCTAssertEqual(sut.prefilledAddTaskURL, "https://example.com/file.zip")
    }

    func testHandleDeepLinkSettingsURL() {
        sut = makeSUT()
        let url = URL(string: "dsget://settings")!

        sut.handleIncomingURL(url)

        XCTAssertTrue(sut.isShowingSettings)
    }

    func testHandleUnknownURL() {
        sut = makeSUT()
        let url = URL(string: "https://example.com")!

        sut.handleIncomingURL(url)

        XCTAssertNil(sut.incomingMagnetURL)
        XCTAssertNil(sut.incomingTorrentURL)
        XCTAssertFalse(sut.isShowingAddTask)
    }

    // MARK: - Error Handling

    func testShowError() {
        sut = makeSUT()
        sut.showError(.network(.offline))

        XCTAssertNotNil(sut.globalError)
        XCTAssertTrue(sut.showingGlobalError)
    }

    func testClearError() {
        sut = makeSUT()
        sut.showError(.network(.offline))
        sut.clearError()

        XCTAssertNil(sut.globalError)
        XCTAssertFalse(sut.showingGlobalError)
    }

    // MARK: - On Login Success

    func testOnLoginSuccessSetsLoggedIn() async {
        sut = makeSUT()
        mockAuthService.getServerResult = Server.create(name: "NAS", host: "nas.local", port: 5001, useHTTPS: true)

        await sut.loadServer()
        sut.isLoggedIn = true

        XCTAssertTrue(sut.isLoggedIn)
        XCTAssertNotNil(sut.currentServer)
    }

    func testOnLoginSuccessLoadsServer() async {
        sut = makeSUT()
        mockAuthService.getServerResult = Server.create(name: "NAS", host: "nas.local", port: 5001, useHTTPS: true)

        await sut.loadServer()

        XCTAssertNotNil(sut.currentServer)
        XCTAssertEqual(sut.currentServer?.configuration.host, "nas.local")
    }

    // MARK: - Check Login Status Error

    func testCheckLoginStatusError() async {
        sut = makeSUT()
        mockAuthService.validateSessionError = DomainError.notAuthenticated

        await sut.checkLoginStatus()

        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertFalse(sut.isCheckingAuth)
    }

    // MARK: - Logout Error Path

    func testLogoutHandlesError() async {
        sut = makeSUT()
        sut.isLoggedIn = true
        mockAuthService.logoutError = DomainError.notAuthenticated

        await sut.logout()

        // Even on error, state should be cleared
        XCTAssertFalse(sut.isLoggedIn)
        XCTAssertNil(sut.currentServer)
    }

    // MARK: - Refresh All

    func testRefreshAllCompletes() async {
        sut = makeSUT()
        mockTaskService.getTasksResult = .success(TasksResult(tasks: [], isFromCache: false))
        mockFeedService.getFeedsResult = .success(FeedsResult(feeds: [], isFromCache: false))

        await sut.refreshAll()

        // Should complete without error
        XCTAssertFalse(sut.showingGlobalError)
    }

}
