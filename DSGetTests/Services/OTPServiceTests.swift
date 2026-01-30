import XCTest
@testable import DSGet

@MainActor
final class OTPServiceTests: XCTestCase {

    private var sut: OTPService!

    override func setUp() {
        super.setUp()
        sut = OTPService()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertFalse(sut.showingSheet)
        XCTAssertEqual(sut.otpCode, "")
    }

    // MARK: - Request and Submit OTP

    func testRequestAndSubmitOTP() async throws {
        let task = Task<String, Error> {
            try await self.sut.requestOTP()
        }

        // Wait briefly for the continuation to be set
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(sut.showingSheet)

        sut.submit(otp: "123456")

        let result = try await task.value
        XCTAssertEqual(result, "123456")
        XCTAssertFalse(sut.showingSheet)
        XCTAssertEqual(sut.otpCode, "")
    }

    // MARK: - Request and Cancel OTP

    func testRequestAndCancelOTP() async {
        let task = Task<String, Error> {
            try await self.sut.requestOTP()
        }

        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertTrue(sut.showingSheet)

        sut.cancel()

        do {
            _ = try await task.value
            XCTFail("Should have thrown CancellationError")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }

        XCTAssertFalse(sut.showingSheet)
        XCTAssertEqual(sut.otpCode, "")
    }

    // MARK: - Submit Without Request

    func testSubmitWithoutRequestDoesNotCrash() {
        sut.submit(otp: "123456")

        XCTAssertFalse(sut.showingSheet)
    }

    func testCancelWithoutRequestDoesNotCrash() {
        sut.cancel()

        XCTAssertFalse(sut.showingSheet)
    }
}
