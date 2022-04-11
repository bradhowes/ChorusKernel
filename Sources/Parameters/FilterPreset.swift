// Copyright © 2021 Brad Howes. All rights reserved.

import AudioUnit

public struct FilterPreset {
  public let rate: AUValue
  public let delay: AUValue
  public let depth: AUValue
  public let dry: AUValue
  public let wet: AUValue
  public let odd90: AUValue

  public init(rate: AUValue, delay: AUValue, depth: AUValue, dry: AUValue, wet: AUValue, odd90: AUValue) {
    self.rate = rate
    self.delay = delay
    self.depth = depth
    self.dry = dry
    self.wet = wet
    self.odd90 = odd90
  }
}
