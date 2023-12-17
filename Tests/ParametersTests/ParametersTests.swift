import XCTest
import AUv3Support
import ParameterAddress
@testable import Parameters
import Kernel

class MockParameterHandler: AUParameterHandler {
  func parameterValueObserverBlock() -> AUImplementorValueObserver {
    self.set
  }
  
  func parameterValueProviderBlock() -> AUImplementorValueProvider {
    self.get
  }
  
  var mapping = [AUParameterAddress: AUValue]()

  func set(_ parameter: AUParameter, value: AUValue) { mapping[parameter.address] = value }
  func get(_ parameter: AUParameter) -> AUValue { mapping[parameter.address] ?? 0.0 }
}

final class ConfigurationTests: XCTestCase {

  func testParameterAddress() throws {
    XCTAssertEqual(ParameterAddress.rate.rawValue, 0)
    XCTAssertEqual(ParameterAddress.odd90.rawValue, 5)

    // Unfortunately, there is no init? for Obj-C enums
    // XCTAssertNil(ParameterAddress(rawValue: ParameterAddress.odd90.rawValue + 1))

    XCTAssertEqual(ParameterAddress.allCases.count, 6)
    XCTAssertTrue(ParameterAddress.allCases.contains(.depth))
    XCTAssertTrue(ParameterAddress.allCases.contains(.rate))
    XCTAssertTrue(ParameterAddress.allCases.contains(.delay))
    XCTAssertTrue(ParameterAddress.allCases.contains(.dry))
    XCTAssertTrue(ParameterAddress.allCases.contains(.wet))
    XCTAssertTrue(ParameterAddress.allCases.contains(.odd90))
  }

  func testParameterDefinitions() throws {
    let aup = Parameters()
    for (index, address) in ParameterAddress.allCases.enumerated() {
      XCTAssertTrue(aup.parameters[index] == aup[address])
    }
  }
}
