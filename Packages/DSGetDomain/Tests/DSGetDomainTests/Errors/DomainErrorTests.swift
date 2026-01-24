import XCTest
@testable import DSGetDomain

final class DomainErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testAuthenticationErrorDescriptions() {
        XCTAssertNotNil(DomainError.notAuthenticated.errorDescription)
        XCTAssertNotNil(DomainError.invalidCredentials.errorDescription)
        XCTAssertNotNil(DomainError.sessionExpired.errorDescription)
        XCTAssertNotNil(DomainError.otpRequired.errorDescription)
        XCTAssertNotNil(DomainError.otpInvalid.errorDescription)
    }

    func testNetworkErrorDescriptions() {
        XCTAssertNotNil(DomainError.noConnection.errorDescription)
        XCTAssertNotNil(DomainError.timeout.errorDescription)
        XCTAssertNotNil(DomainError.serverUnreachable.errorDescription)
    }

    func testAPIErrorDescription() {
        let error = DomainError.apiError(code: 500, message: "Internal error")
        XCTAssertTrue(error.errorDescription?.contains("500") == true)
        XCTAssertTrue(error.errorDescription?.contains("Internal error") == true)
    }

    // MARK: - RequiresRelogin Tests

    func testRequiresReloginForAuthErrors() {
        XCTAssertTrue(DomainError.notAuthenticated.requiresRelogin)
        XCTAssertTrue(DomainError.sessionExpired.requiresRelogin)
        XCTAssertTrue(DomainError.invalidCredentials.requiresRelogin)
        XCTAssertTrue(DomainError.reloginFailed.requiresRelogin)
    }

    func testRequiresReloginFalseForOtherErrors() {
        XCTAssertFalse(DomainError.noConnection.requiresRelogin)
        XCTAssertFalse(DomainError.timeout.requiresRelogin)
        XCTAssertFalse(DomainError.invalidDownloadURL.requiresRelogin)
    }

    // MARK: - IsConnectivityError Tests

    func testIsConnectivityErrorTrue() {
        XCTAssertTrue(DomainError.noConnection.isConnectivityError)
        XCTAssertTrue(DomainError.timeout.isConnectivityError)
        XCTAssertTrue(DomainError.serverUnreachable.isConnectivityError)
    }

    func testIsConnectivityErrorFalse() {
        XCTAssertFalse(DomainError.notAuthenticated.isConnectivityError)
        XCTAssertFalse(DomainError.invalidResponse.isConnectivityError)
        XCTAssertFalse(DomainError.cacheEmpty.isConnectivityError)
    }

    // MARK: - CanUseCacheFallback Tests

    func testCanUseCacheFallback() {
        XCTAssertTrue(DomainError.noConnection.canUseCacheFallback)
        XCTAssertTrue(DomainError.timeout.canUseCacheFallback)
        XCTAssertTrue(DomainError.serverUnreachable.canUseCacheFallback)

        XCTAssertFalse(DomainError.invalidCredentials.canUseCacheFallback)
        XCTAssertFalse(DomainError.invalidResponse.canUseCacheFallback)
    }

    // MARK: - IsRecoverable Tests

    func testIsRecoverable() {
        XCTAssertTrue(DomainError.timeout.isRecoverable)
        XCTAssertTrue(DomainError.serverUnreachable.isRecoverable)
        XCTAssertTrue(DomainError.sessionExpired.isRecoverable)
        XCTAssertTrue(DomainError.otpRequired.isRecoverable)

        XCTAssertFalse(DomainError.invalidCredentials.isRecoverable)
        XCTAssertFalse(DomainError.invalidDownloadURL.isRecoverable)
    }

    // MARK: - Title Tests

    func testErrorTitles() {
        XCTAssertEqual(DomainError.notAuthenticated.title, "Authentication Error")
        XCTAssertEqual(DomainError.noConnection.title, "Connection Error")
        XCTAssertEqual(DomainError.invalidResponse.title, "Server Error")
        XCTAssertEqual(DomainError.taskNotFound(TaskID("1")).title, "Task Error")
        XCTAssertEqual(DomainError.feedNotFound(FeedID("1")).title, "Feed Error")
        XCTAssertEqual(DomainError.pathNotFound("/test").title, "File System Error")
        XCTAssertEqual(DomainError.cacheEmpty.title, "Cache Error")
        XCTAssertEqual(DomainError.unknown("test").title, "Error")
    }

    // MARK: - Equatable Tests

    func testEquatableSimpleCases() {
        XCTAssertEqual(DomainError.notAuthenticated, DomainError.notAuthenticated)
        XCTAssertEqual(DomainError.timeout, DomainError.timeout)
        XCTAssertNotEqual(DomainError.notAuthenticated, DomainError.timeout)
    }

    func testEquatableWithAssociatedValues() {
        let error1 = DomainError.apiError(code: 500, message: "Error")
        let error2 = DomainError.apiError(code: 500, message: "Error")
        let error3 = DomainError.apiError(code: 404, message: "Not found")

        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
}
