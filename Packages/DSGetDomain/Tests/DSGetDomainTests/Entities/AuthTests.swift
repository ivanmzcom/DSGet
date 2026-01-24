import XCTest
@testable import DSGetDomain

final class AuthTests: XCTestCase {

    // MARK: - ServerConfiguration Tests

    func testServerConfigurationInit() {
        let config = ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        XCTAssertEqual(config.host, "nas.local")
        XCTAssertEqual(config.port, 5001)
        XCTAssertTrue(config.useHTTPS)
    }

    func testServerConfigurationScheme() {
        let httpsConfig = ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        XCTAssertEqual(httpsConfig.scheme, "https")

        let httpConfig = ServerConfiguration(host: "nas.local", port: 5000, useHTTPS: false)
        XCTAssertEqual(httpConfig.scheme, "http")
    }

    func testServerConfigurationBaseURL() {
        let config = ServerConfiguration(host: "nas.local", port: 5001, useHTTPS: true)
        XCTAssertEqual(config.baseURL?.absoluteString, "https://nas.local:5001")
    }

    func testServerConfigurationDisplayName() {
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        XCTAssertEqual(config.displayName, "nas.local:5001")
    }

    func testServerConfigurationFactoryMethods() {
        let httpsConfig = ServerConfiguration.https(host: "nas.local")
        XCTAssertEqual(httpsConfig.port, 5001)
        XCTAssertTrue(httpsConfig.useHTTPS)

        let httpConfig = ServerConfiguration.http(host: "nas.local")
        XCTAssertEqual(httpConfig.port, 5000)
        XCTAssertFalse(httpConfig.useHTTPS)
    }

    func testServerConfigurationValidation() {
        let validConfig = ServerConfiguration(host: "nas.local", port: 5001)
        XCTAssertTrue(validConfig.isValid)
        XCTAssertNil(validConfig.validationError)

        let emptyHost = ServerConfiguration(host: "", port: 5001)
        XCTAssertFalse(emptyHost.isValid)
        XCTAssertNotNil(emptyHost.validationError)

        let invalidPort = ServerConfiguration(host: "nas.local", port: 0)
        XCTAssertFalse(invalidPort.isValid)
        XCTAssertNotNil(invalidPort.validationError)
    }

    // MARK: - Session Tests

    func testSessionInit() {
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let session = Session(sessionID: "sid123", serverConfiguration: config)

        XCTAssertEqual(session.sessionID, "sid123")
        XCTAssertEqual(session.serverConfiguration.host, "nas.local")
    }

    func testSessionIsValid() {
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let validSession = Session(sessionID: "sid123", serverConfiguration: config)
        XCTAssertTrue(validSession.isValid)

        let invalidSession = Session(sessionID: "", serverConfiguration: config)
        XCTAssertFalse(invalidSession.isValid)
    }

    func testSessionAge() {
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let session = Session(
            sessionID: "sid123",
            serverConfiguration: config,
            createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )

        XCTAssertGreaterThan(session.age, 3599)
        XCTAssertLessThan(session.age, 3602)
    }

    func testSessionMightBeExpired() {
        let config = ServerConfiguration(host: "nas.local", port: 5001)

        let recentSession = Session(
            sessionID: "sid123",
            serverConfiguration: config,
            createdAt: Date()
        )
        XCTAssertFalse(recentSession.mightBeExpired())

        let oldSession = Session(
            sessionID: "sid123",
            serverConfiguration: config,
            createdAt: Date().addingTimeInterval(-25 * 60 * 60) // 25 hours ago
        )
        XCTAssertTrue(oldSession.mightBeExpired())
    }

    // MARK: - Credentials Tests

    func testCredentialsInit() {
        let credentials = Credentials(username: "admin", password: "secret")
        XCTAssertEqual(credentials.username, "admin")
        XCTAssertEqual(credentials.password, "secret")
        XCTAssertNil(credentials.otpCode)
    }

    func testCredentialsWithOTP() {
        let credentials = Credentials(username: "admin", password: "secret")
        let withOTP = credentials.withOTP("123456")

        XCTAssertEqual(withOTP.username, "admin")
        XCTAssertEqual(withOTP.password, "secret")
        XCTAssertEqual(withOTP.otpCode, "123456")
    }

    func testCredentialsWithoutOTP() {
        let credentials = Credentials(username: "admin", password: "secret", otpCode: "123456")
        let withoutOTP = credentials.withoutOTP()

        XCTAssertEqual(withoutOTP.username, "admin")
        XCTAssertEqual(withoutOTP.password, "secret")
        XCTAssertNil(withoutOTP.otpCode)
    }

    // MARK: - LoginRequest Tests

    func testLoginRequestInit() {
        let config = ServerConfiguration(host: "nas.local", port: 5001)
        let credentials = Credentials(username: "admin", password: "secret")
        let request = LoginRequest(configuration: config, credentials: credentials)

        XCTAssertEqual(request.configuration.host, "nas.local")
        XCTAssertEqual(request.credentials.username, "admin")
    }
}
