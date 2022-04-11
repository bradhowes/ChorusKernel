// Copyright © 2021 Brad Howes. All rights reserved.

import AudioToolbox

/**
 Collection of values for the parameters of the audio unit. Treated as a unit that can be named and recalled using the
 AUv3 APIs.
 */
public struct Configuration {
  public let rate: AUValue
  public let delay: AUValue
  public let depth: AUValue
  public let dry: AUValue
  public let wet: AUValue
  public let odd90: AUValue

  /**
   Define a new configuration.

   - parameter rate: the rate setting
   - parameter delay: the delay setting
   - parameter depth: the depth setting
   - parameter dry: the dry (original audio) mix setting
   - parameter wet: the wet (effect audio) mix setting
   - parameter odd90: the odd 90° setting
   */
  public init(rate: AUValue, delay: AUValue, depth: AUValue, dry: AUValue, wet: AUValue, odd90: AUValue) {
    self.rate = rate
    self.delay = delay
    self.depth = depth
    self.dry = dry
    self.wet = wet
    self.odd90 = odd90
  }
}
