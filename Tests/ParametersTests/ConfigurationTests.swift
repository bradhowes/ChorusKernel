import XCTest
@testable import Parameters

final class AudioUnitParametersTests: XCTestCase {

  func testInit() throws {
    
    let a = Configuration(rate: 1.0, delay: 2.0, depth: 3.0, dry: 4.0, wet: 5.0, odd90: 0.0)

    XCTAssertEqual(a.rate, 1.0)
    XCTAssertEqual(a.delay, 2.0)
    XCTAssertEqual(a.depth, 3.0)
    XCTAssertEqual(a.dry, 4.0)
    XCTAssertEqual(a.wet, 5.0)
    XCTAssertEqual(a.odd90, 0.0)
  }
}
