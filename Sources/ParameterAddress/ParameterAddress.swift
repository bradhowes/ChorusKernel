import AudioUnit.AUParameters
import AUv3Support

/**
 These are the unique addresses for the runtime parameters used by the audio unit.

 NOTE: the raw values of this enum are used to index into an array of AUParameter values, so be sure to start at 0 and
 have no gaps. Perhaps not the best way to go, but it works and is quite simple.
 */
@objc public enum ParameterAddress: UInt64, CaseIterable {
  /// The frequency in Hertz of the low-frequency oscillator (LFO) used to delay the input signal
  case rate = 0
  /// The max delay in milliseconds to apply to the input signal
  case delay
  /// Percentage that the delay tap can vary from the `delay` setting to zero. A value of 100 means full travel from
  /// `delay` to 0, while 50 would mean oscillations between `delay` and 0.5 x `delay`.
  case depth
  /// Percentage of the original signal to mix into the output.
  case dry
  /// Percentage of the delayed signal to mix into the output.
  case wet
  /// When true, "odd" audio channels (eg. right in stereo) are shifted 90° in phase from the even channels.
  case odd90
};

public extension ParameterAddress {

  /// Obtain a ParameterDefinition for a parameter address enum.
  var parameterDefinition: ParameterDefinition {
    let maxDelay: AUValue = 10.0
    switch self {
    case .rate: return .defFloat("rate", localized: "Rate", address: ParameterAddress.rate,
                                 range: 0.01...8.0, unit: .hertz)
    case .delay: return .defFloat("delay", localized: "Delay", address: ParameterAddress.delay,
                                  range: 0.0...maxDelay, unit: .milliseconds)
    case .depth: return .defPercent("depth", localized: "Depth", address: ParameterAddress.depth)
    case .dry: return .defPercent("dry", localized: "Dry", address: ParameterAddress.dry)
    case .wet: return .defPercent("wet", localized: "Wet", address: ParameterAddress.wet)
    case .odd90: return .defBool("odd90", localized: "Odd 90°", address: ParameterAddress.odd90)
    }
  }
}

extension AUParameter {
  public var parameterAddress: ParameterAddress? { .init(rawValue: self.address) }
}

/// Allow enum values to serve as AUParameterAddress values.
extension ParameterAddress: ParameterAddressProvider {
  public var parameterAddress: AUParameterAddress { UInt64(self.rawValue) }
}

public extension ParameterAddressHolder {

  func setParameterAddress(_ address: ParameterAddress) { parameterAddress = address.rawValue }

  var parameterAddress: ParameterAddress? {
    let raw: AUParameterAddress = parameterAddress
    return ParameterAddress(rawValue: raw)
  }
}

extension ParameterAddress: CustomStringConvertible {
  public var description: String { "<ParameterAddress: '\(parameterDefinition.identifier)' \(rawValue)>" }
}
