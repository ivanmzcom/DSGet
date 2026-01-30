import XCTest
@testable import DSGetCore
@testable import DSGet

// MARK: - Test Helper Class with Offline Support

@MainActor
final class TestViewModelWithOfflineMode: DomainErrorHandling, OfflineModeSupporting {
    var currentError: DSGetError?
    var showingError: Bool = false
    var isOfflineMode: Bool = false
}

// MARK: - Test Helper Class without Offline Support

@MainActor
final class TestViewModelWithoutOfflineMode: DomainErrorHandling {
    var currentError: DSGetError?
    var showingError: Bool = false
}

// MARK: - Tests

@MainActor
final class DomainErrorHandlingTests: XCTestCase {

    private var viewModelWithOffline: TestViewModelWithOfflineMode!
    private var viewModelWithoutOffline: TestViewModelWithoutOfflineMode!
    private var notificationReceived: Bool = false
    private var notificationObserver: NSObjectProtocol?

    override func setUp() {
        super.setUp()
        viewModelWithOffline = TestViewModelWithOfflineMode()
        viewModelWithoutOffline = TestViewModelWithoutOfflineMode()
        notificationReceived = false
    }

    override func tearDown() {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
            notificationObserver = nil
        }
        super.tearDown()
    }

    // MARK: - Connectivity Errors

    func testHandleDomainErrorNoConnectionSetsOfflineMode() {
        viewModelWithOffline.handleDomainError(.noConnection)

        XCTAssertTrue(viewModelWithOffline.isOfflineMode)
        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .network(.offline) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected network offline error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleDomainErrorTimeoutSetsOfflineMode() {
        viewModelWithOffline.handleDomainError(.timeout)

        XCTAssertTrue(viewModelWithOffline.isOfflineMode)
        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .network(.timeout) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected network timeout error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleDomainErrorServerUnreachableSetsOfflineMode() {
        viewModelWithOffline.handleDomainError(.serverUnreachable)

        XCTAssertTrue(viewModelWithOffline.isOfflineMode)
        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .network(.requestFailed) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected network requestFailed error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleDomainErrorConnectivityDoesNotSetOfflineModeWhenNotSupported() {
        viewModelWithoutOffline.handleDomainError(.noConnection)

        XCTAssertTrue(viewModelWithoutOffline.showingError)

        if case .network(.offline) = viewModelWithoutOffline.currentError {
            // Success - error is set correctly
        } else {
            XCTFail("Expected network offline error, got \(String(describing: viewModelWithoutOffline.currentError))")
        }
    }

    // MARK: - Authentication Errors

    func testHandleDomainErrorNotAuthenticatedPostsNotification() {
        let expectation = expectation(description: "Notification posted")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { _ in
            self.notificationReceived = true
            expectation.fulfill()
        }

        viewModelWithOffline.handleDomainError(.notAuthenticated)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .authentication(.notLoggedIn) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected authentication notLoggedIn error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleDomainErrorInvalidCredentialsPostsNotification() {
        let expectation = expectation(description: "Notification posted")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { _ in
            self.notificationReceived = true
            expectation.fulfill()
        }

        viewModelWithOffline.handleDomainError(.invalidCredentials)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .authentication(.invalidCredentials) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected authentication invalidCredentials error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleDomainErrorSessionExpiredPostsNotification() {
        let expectation = expectation(description: "Notification posted")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { _ in
            self.notificationReceived = true
            expectation.fulfill()
        }

        viewModelWithOffline.handleDomainError(.sessionExpired)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .authentication(.notLoggedIn) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected authentication notLoggedIn error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    // MARK: - Cache Errors (Silent)

    func testHandleDomainErrorCacheEmptySetsErrorToNil() {
        viewModelWithOffline.handleDomainError(.cacheEmpty)

        XCTAssertNil(viewModelWithOffline.currentError)
        XCTAssertFalse(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)
    }

    func testHandleDomainErrorCacheExpiredSetsErrorToNil() {
        viewModelWithOffline.handleDomainError(.cacheExpired)

        XCTAssertNil(viewModelWithOffline.currentError)
        XCTAssertFalse(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)
    }

    // MARK: - OTP Errors

    func testHandleDomainErrorOTPRequiredMapsCorrectly() {
        viewModelWithOffline.handleDomainError(.otpRequired)

        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .api(.otpRequired) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected api otpRequired error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleDomainErrorOTPInvalidMapsToServerError() {
        viewModelWithOffline.handleDomainError(.otpInvalid)

        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .api(.serverError(let code, _)) = viewModelWithOffline.currentError {
            XCTAssertEqual(code, -1)
        } else {
            XCTFail("Expected api serverError, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    // MARK: - API Errors

    func testHandleDomainErrorAPIErrorMapsCorrectly() {
        viewModelWithOffline.handleDomainError(.apiError(code: 404, message: "Not found"))

        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .api(.serverError(let code, let message)) = viewModelWithOffline.currentError {
            XCTAssertEqual(code, 404)
            XCTAssertEqual(message, "Not found")
        } else {
            XCTFail("Expected api serverError, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    // MARK: - Generic Error Handling

    func testHandleErrorWithDomainErrorDelegatesToHandleDomainError() {
        let domainError: Error = DomainError.noConnection
        viewModelWithOffline.handleError(domainError)

        XCTAssertTrue(viewModelWithOffline.isOfflineMode)
        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .network(.offline) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected network offline error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleErrorWithNonDomainErrorUsesDSGetErrorFrom() {
        let urlError = URLError(.notConnectedToInternet)
        viewModelWithOffline.handleError(urlError)

        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .network(.offline) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected network offline error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleErrorWithDSGetErrorThatRequiresReloginPostsNotification() {
        let expectation = expectation(description: "Notification posted")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { _ in
            self.notificationReceived = true
            expectation.fulfill()
        }

        let authError: Error = DSGetError.authentication(.notLoggedIn)
        viewModelWithOffline.handleError(authError)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .authentication(.notLoggedIn) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected authentication notLoggedIn error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    func testHandleErrorWithSessionExpiredPostsNotification() {
        let expectation = expectation(description: "Notification posted")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { _ in
            self.notificationReceived = true
            expectation.fulfill()
        }

        let sessionError: Error = DSGetError.api(.sessionExpired)
        viewModelWithOffline.handleError(sessionError)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(viewModelWithOffline.showingError)

        if case .api(.sessionExpired) = viewModelWithOffline.currentError {
            // Success
        } else {
            XCTFail("Expected api sessionExpired error, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }

    // MARK: - Other Errors

    func testHandleDomainErrorReloginFailedPostsNotification() {
        let expectation = expectation(description: "Notification posted")

        notificationObserver = NotificationCenter.default.addObserver(
            forName: .authenticationRequired,
            object: nil,
            queue: .main
        ) { _ in
            self.notificationReceived = true
            expectation.fulfill()
        }

        viewModelWithOffline.handleDomainError(.reloginFailed)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(notificationReceived)
        XCTAssertTrue(viewModelWithOffline.showingError)
    }

    func testHandleDomainErrorUnknownMapsToServerError() {
        viewModelWithOffline.handleDomainError(.unknown("Custom error message"))

        XCTAssertTrue(viewModelWithOffline.showingError)
        XCTAssertFalse(viewModelWithOffline.isOfflineMode)

        if case .api(.serverError(let code, let message)) = viewModelWithOffline.currentError {
            XCTAssertEqual(code, -1)
            XCTAssertEqual(message, "Custom error message")
        } else {
            XCTFail("Expected api serverError, got \(String(describing: viewModelWithOffline.currentError))")
        }
    }
}
