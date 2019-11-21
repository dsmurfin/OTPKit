import XCTest
@testable import OTPKit

final class OTPKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(OTPKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
