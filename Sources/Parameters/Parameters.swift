// Copyright © 2022 Brad Howes. All rights reserved.

import AUv3Support
import CoreAudioKit
import Foundation
import ParameterAddress
import os.log

private extension Array where Element == AUParameter {
  subscript(index: ParameterAddress) -> AUParameter { self[Int(index.rawValue)] }
}

/**
 Definitions for the runtime parameters of the filter.
 */
public final class Parameters: NSObject, ParameterSource {

  private let log = Shared.logger("Parameters")

  /// Array of AUParameter entities created from ParameterAddress value definitions.
  public let parameters: [AUParameter] = ParameterAddress.allCases.map { $0.parameterDefinition.parameter }

  /// Array of 2-tuple values that pair a factory preset name and its definition
  public let factoryPresetValues: [(name: String, preset: Configuration)] = [
    ("Cadet", .init(rate: 1.68, delay: 8.3, depth: 100, dry: 50, wet: 100, odd90: 0)),
    ("Wide Cadet", .init(rate: 1.68, delay: 8.3, depth: 100, dry: 50, wet: 100, odd90: 1)),
    ("Wavy", .init(rate: 5.1, delay: 8.3, depth: 100, dry: 50, wet: 100, odd90: 0)),
    ("Wavy Pong", .init(rate: 5.1, delay: 8.3, depth: 100, dry: 50, wet: 100, odd90: 1)),
    ("Shimmer", .init(rate: 10.0, delay: 1.75, depth: 1.4, dry: 50, wet: 100, odd90: 1)),
    ("Disturbed", .init(rate: 5.0, delay: 50.0, depth: 100.0, dry: 50, wet: 100, odd90: 1)),
  ]

  /// Array of `AUAudioUnitPreset` for the factory presets.
  public var factoryPresets: [AUAudioUnitPreset] {
    factoryPresetValues.enumerated().map { .init(number: $0.0, name: $0.1.name ) }
  }

  /// AUParameterTree created with the parameter definitions for the audio unit
  public let parameterTree: AUParameterTree
  /// Obtain the parameter setting that determines how fast the LFO operates
  public var rate: AUParameter { parameters[.rate] }
  /// Obtain the parameter setting that determines the minimum delay applied incoming samples. The actual delay value is
  /// this value plus the `depth` times the current LFO value.
  public var delay: AUParameter { parameters[.delay] }
  /// Obtain the parameter setting that determines how much variation in time there is when reading values from
  /// the delay buffer.
  public var depth: AUParameter { parameters[.depth] }
  /// Obtain the `depth` parameter setting
  public var dryMix: AUParameter { parameters[.dry] }
  /// Obtain the `wetMix` parameter setting
  public var wetMix: AUParameter { parameters[.wet] }
  /// Obtain the `odd90` parameter setting
  public var odd90: AUParameter { parameters[.odd90] }

  /**
   Create a new AUParameterTree for the defined filter parameters.
   */
  override public init() {
    parameterTree = AUParameterTree.createTree(withChildren: parameters)
    super.init()
    installParameterValueFormatter()
  }
}

extension Parameters {

  private var missingParameter: AUParameter { fatalError() }

  /// Apply a factory preset -- user preset changes are handled by changing AUParameter values through the audio unit's
  /// `fullState` attribute.
  public func useFactoryPreset(_ preset: AUAudioUnitPreset) {
    os_log(.info, log: log, "useFactoryPreset - %d '%{public}s'", preset.number, preset.name)
    if preset.number >= 0 {
      setValues(factoryPresetValues[preset.number].preset)
    }
  }

  /**
   Access an AUParameter via its address.

   - parameter address: the address to look for
   - returns: the AUParameter that was found
   */
  public subscript(address: ParameterAddress) -> AUParameter {
    parameterTree.parameter(withAddress: address.parameterAddress) ?? missingParameter
  }

  /**
   Obtain a formatter for a parameter address. A format converts a parameter's value into a string representation.

   - parameter address: the address to look for
   - returns: the formatter for the parameter
   */
  public func valueFormatter(_ address: ParameterAddress) -> (AUValue) -> String { self[address].valueFormatter }

  private func installParameterValueFormatter() {
    parameterTree.implementorStringFromValueCallback = { param, valuePtr in
      let value: AUValue
      if let valuePtr = valuePtr {
        value = valuePtr.pointee
      } else {
        value = param.value
      }
      return String(format: param.stringFormatForValue, value) + param.suffix
    }
  }

  /**
   Accept new values for the filter settings. Uses the AUParameterTree framework for communicating the changes to the
   AudioUnit.
   */
  public func setValues(_ preset: Configuration) {
    rate.value = preset.rate
    delay.value = preset.delay
    depth.value = preset.depth
    dryMix.value = preset.dry
    wetMix.value = preset.wet
    odd90.value = preset.odd90
  }
}

extension AUParameter {

  /// Obtain string to use to separate a formatted value from its units name
  var unitSeparator: String {
    switch parameterAddress {
    case .rate, .delay: return " "
    default: return ""
    }
  }

  /// Obtain the suffix to apply to a formatted value
  var suffix: String { unitSeparator + (unitName ?? "") }

  /// Obtain the format to use in String(format:value) when formatting a values
  var stringFormatForValue: String {
    switch parameterAddress {
    case .depth, .dry, .wet: return "%.0f"
    default: return "%.2f"
    }
  }

  /// Obtain a closure that will format parameter values into a string
  var valueFormatter: (AUValue) -> String {
    { value in String(format: self.stringFormatForValue, value) + self.suffix }
  }
}

