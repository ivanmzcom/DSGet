import Foundation
@testable import DSGetData
@testable import DSGetDomain

/// Test configuration that reads credentials from environment variables.
/// NEVER commit actual credentials to the codebase.
///
/// To run integration tests, set the following environment variables:
/// - DSGET_TEST_HOST: The NAS hostname (e.g., "nas.example.com")
/// - DSGET_TEST_PORT: The NAS port (e.g., "443")
/// - DSGET_TEST_USERNAME: The username
/// - DSGET_TEST_PASSWORD: The password
/// - DSGET_TEST_USE_HTTPS: Whether to use HTTPS ("true" or "false"), defaults to "true"
///
/// Example (in terminal before running tests):
/// ```
/// export DSGET_TEST_HOST="nas.example.com"
/// export DSGET_TEST_PORT="443"
/// export DSGET_TEST_USERNAME="user"
/// export DSGET_TEST_PASSWORD="password"
/// swift test
/// ```
///
/// Or in Xcode, edit the test scheme and add environment variables.
struct TestConfiguration {

    static let shared = TestConfiguration()

    let host: String?
    let port: Int?
    let username: String?
    let password: String?
    let useHTTPS: Bool

    var isConfigured: Bool {
        host != nil && port != nil && username != nil && password != nil
    }

    init() {
        self.host = ProcessInfo.processInfo.environment["DSGET_TEST_HOST"]
        self.port = ProcessInfo.processInfo.environment["DSGET_TEST_PORT"].flatMap { Int($0) }
        self.username = ProcessInfo.processInfo.environment["DSGET_TEST_USERNAME"]
        self.password = ProcessInfo.processInfo.environment["DSGET_TEST_PASSWORD"]
        self.useHTTPS = ProcessInfo.processInfo.environment["DSGET_TEST_USE_HTTPS"] != "false"
    }

    func getServerConfiguration() -> ServerConfiguration? {
        guard let host = host, let port = port else { return nil }
        return ServerConfiguration(host: host, port: port, useHTTPS: useHTTPS)
    }

    func getCredentials() -> Credentials? {
        guard let username = username, let password = password else { return nil }
        return Credentials(username: username, password: password)
    }

    func getServer() -> Server? {
        guard let config = getServerConfiguration() else { return nil }
        return Server(
            name: "Test Server",
            configuration: config
        )
    }
}

/// Skip message for when integration tests cannot run
let integrationTestSkipMessage = """
    Integration tests require environment variables to be set.
    Set DSGET_TEST_HOST, DSGET_TEST_PORT, DSGET_TEST_USERNAME, and DSGET_TEST_PASSWORD.
    """
