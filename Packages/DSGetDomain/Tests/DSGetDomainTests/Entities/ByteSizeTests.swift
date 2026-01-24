import XCTest
@testable import DSGetDomain

final class ByteSizeTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInitWithBytes() {
        let size = ByteSize(bytes: 1024)
        XCTAssertEqual(size.bytes, 1024)
    }

    func testZero() {
        let size = ByteSize.zero
        XCTAssertEqual(size.bytes, 0)
    }

    // MARK: - Factory Methods

    func testKilobytes() {
        let size = ByteSize.kilobytes(1)
        XCTAssertEqual(size.bytes, 1024)
    }

    func testMegabytes() {
        let size = ByteSize.megabytes(1)
        XCTAssertEqual(size.bytes, 1024 * 1024)
    }

    func testGigabytes() {
        let size = ByteSize.gigabytes(1)
        XCTAssertEqual(size.bytes, 1024 * 1024 * 1024)
    }

    func testTerabytes() {
        let size = ByteSize.terabytes(1)
        XCTAssertEqual(size.bytes, Int64(1024) * 1024 * 1024 * 1024)
    }

    // MARK: - Computed Properties

    func testKilobytesValue() {
        let size = ByteSize(bytes: 2048)
        XCTAssertEqual(size.kilobytes, 2.0, accuracy: 0.001)
    }

    func testMegabytesValue() {
        let size = ByteSize.megabytes(2.5)
        XCTAssertEqual(size.megabytes, 2.5, accuracy: 0.001)
    }

    func testGigabytesValue() {
        let size = ByteSize.gigabytes(3)
        XCTAssertEqual(size.gigabytes, 3.0, accuracy: 0.001)
    }

    // MARK: - Formatting

    func testFormattedBytes() {
        let size = ByteSize(bytes: 500)
        // ByteCountFormatter may output "500 bytes" or "500 B" depending on locale/OS
        XCTAssertTrue(size.formatted.contains("500"))
    }

    func testFormattedKilobytes() {
        let size = ByteSize.kilobytes(1.5)
        XCTAssertTrue(size.formatted.contains("KB"))
    }

    func testFormattedMegabytes() {
        let size = ByteSize.megabytes(100)
        XCTAssertTrue(size.formatted.contains("MB"))
    }

    func testFormattedGigabytes() {
        let size = ByteSize.gigabytes(2.5)
        XCTAssertTrue(size.formatted.contains("GB"))
    }

    func testFormattedTerabytes() {
        let size = ByteSize.terabytes(1.5)
        XCTAssertTrue(size.formatted.contains("TB"))
    }

    // MARK: - Comparison

    func testEquality() {
        let size1 = ByteSize(bytes: 1024)
        let size2 = ByteSize.kilobytes(1)
        XCTAssertEqual(size1, size2)
    }

    func testComparable() {
        let smaller = ByteSize.megabytes(1)
        let larger = ByteSize.gigabytes(1)
        XCTAssertTrue(smaller < larger)
    }

    // MARK: - Arithmetic

    func testAddition() {
        let size1 = ByteSize.megabytes(1)
        let size2 = ByteSize.megabytes(2)
        let result = size1 + size2
        XCTAssertEqual(result, ByteSize.megabytes(3))
    }

    func testSubtraction() {
        let size1 = ByteSize.megabytes(3)
        let size2 = ByteSize.megabytes(1)
        let result = size1 - size2
        XCTAssertEqual(result, ByteSize.megabytes(2))
    }
}
