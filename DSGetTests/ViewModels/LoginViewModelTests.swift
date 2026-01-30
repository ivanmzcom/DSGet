import XCTest
@testable import DSGetCore
@testable import DSGet

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var mockAuthService: MockAuthService!
    private var sut: LoginViewModel!

    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
    }

    // MARK: - Helpers

    private func makeSUT() -> LoginViewModel {
        LoginViewModel(authService: mockAuthService)
    }

    private func makeSession() -> Session {
        Session(
            sessionID: "test_sid",
            serverConfiguration: ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        )
    }

    // MARK: - Form Validation

    func testFormValidWithAllFields() {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "password"
        sut.port = 5001

        XCTAssertTrue(sut.isFormValid)
    }

    func testFormInvalidEmptyHost() {
        sut = makeSUT()
        sut.host = ""
        sut.username = "admin"
        sut.password = "password"

        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidEmptyUsername() {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = ""
        sut.password = "password"

        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidEmptyPassword() {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = ""

        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidZeroPort() {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "password"
        sut.port = 0

        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidPortTooHigh() {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "password"
        sut.port = 70_000

        XCTAssertFalse(sut.isFormValid)
    }

    func testFormInvalidWhitespaceOnlyHost() {
        sut = makeSUT()
        sut.host = "   "
        sut.username = "admin"
        sut.password = "password"

        XCTAssertFalse(sut.isFormValid)
    }

    // MARK: - Port String Binding

    func testPortStringGet() {
        sut = makeSUT()
        sut.port = 5001
        XCTAssertEqual(sut.portString, "5001")
    }

    func testPortStringGetZero() {
        sut = makeSUT()
        sut.port = 0
        XCTAssertEqual(sut.portString, "")
    }

    func testPortStringSet() {
        sut = makeSUT()
        sut.portString = "8080"
        XCTAssertEqual(sut.port, 8080)
    }

    func testPortStringSetEmpty() {
        sut = makeSUT()
        sut.portString = ""
        XCTAssertEqual(sut.port, 0)
    }

    func testPortStringSetInvalid() {
        sut = makeSUT()
        sut.port = 5001
        sut.portString = "abc"
        XCTAssertEqual(sut.port, 5001) // unchanged
    }

    // MARK: - Login

    func testLoginSuccess() async {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "password"
        sut.port = 5001
        mockAuthService.loginResult = .success(makeSession())

        var callbackCalled = false
        sut.onLoginSuccess = { callbackCalled = true }

        await sut.login()

        XCTAssertTrue(mockAuthService.loginCalled)
        XCTAssertTrue(mockAuthService.saveServerCalled)
        XCTAssertTrue(callbackCalled)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoginSendsCorrectCredentials() async {
        sut = makeSUT()
        sut.host = "mynas.local"
        sut.username = "admin"
        sut.password = "secret"
        sut.port = 5001
        sut.useHTTPS = true
        mockAuthService.loginResult = .success(makeSession())

        await sut.login()

        let request = mockAuthService.lastLoginRequest
        XCTAssertEqual(request?.configuration.host, "mynas.local")
        XCTAssertEqual(request?.configuration.port, 5001)
        XCTAssertTrue(request?.configuration.useHTTPS ?? false)
        XCTAssertEqual(request?.credentials.username, "admin")
        XCTAssertEqual(request?.credentials.password, "secret")
    }

    func testLoginWithOTP() async {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "password"
        sut.otpCode = "123456"
        mockAuthService.loginResult = .success(makeSession())

        await sut.login()

        XCTAssertEqual(mockAuthService.lastLoginRequest?.credentials.otpCode, "123456")
    }

    func testLoginWithEmptyOTPSendsNil() async {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "password"
        sut.otpCode = ""
        mockAuthService.loginResult = .success(makeSession())

        await sut.login()

        XCTAssertNil(mockAuthService.lastLoginRequest?.credentials.otpCode)
    }

    func testLoginError() async {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.username = "admin"
        sut.password = "wrong"
        mockAuthService.loginResult = .failure(DomainError.invalidCredentials)

        await sut.login()

        XCTAssertNotNil(sut.currentError)
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoginDoesNothingWithInvalidForm() async {
        sut = makeSUT()
        sut.host = ""
        sut.username = ""
        sut.password = ""

        await sut.login()

        XCTAssertFalse(mockAuthService.loginCalled)
    }

    func testLoginUsesHostAsServerNameWhenEmpty() async {
        sut = makeSUT()
        sut.host = "nas.local"
        sut.serverName = ""
        sut.username = "admin"
        sut.password = "password"
        mockAuthService.loginResult = .success(makeSession())

        await sut.login()

        // Server name should default to host
        XCTAssertTrue(mockAuthService.saveServerCalled)
        XCTAssertEqual(mockAuthService.lastSavedServer?.name, "nas.local")
    }

    func testLoginUsesCustomServerName() async {
        sut = makeSUT()
        sut.host = "192.168.1.100"
        sut.serverName = "My NAS"
        sut.username = "admin"
        sut.password = "password"
        mockAuthService.loginResult = .success(makeSession())

        await sut.login()

        XCTAssertEqual(mockAuthService.lastSavedServer?.name, "My NAS")
    }

    // MARK: - Reset

    func testReset() {
        sut = makeSUT()
        sut.password = "secret"
        sut.otpCode = "123456"
        sut.showingError = true
        sut.currentError = .authentication(.invalidCredentials)

        sut.reset()

        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.otpCode, "")
        XCTAssertFalse(sut.showingError)
        XCTAssertNil(sut.currentError)
    }
}
