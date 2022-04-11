#import "C++/Kernel.hpp"

// This must be done in a source file -- include files cannot see the Swift bridging file which contains the definition
// of ParameterAddress.

@import ParameterAddress;

void Kernel::setParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) noexcept {
  os_log_with_type(log_, OS_LOG_TYPE_DEBUG, "setRampedParameterValue - %llul %f %d", address, value, duration);
  assert(duration >= 0);

  if (duration > rampRemaining_) rampRemaining_ = duration;
  switch (address) {
    case ParameterAddressRate: setRate(value, duration); break;
    case ParameterAddressDepth: depth_.set(value, duration); break;
    case ParameterAddressDelay: delay_.set(value, duration); break;
    case ParameterAddressDry: dryMix_.set(value, duration); break;
    case ParameterAddressWet: wetMix_.set(value, duration); break;
    case ParameterAddressOdd90: odd90_.set(value); break;
  }
}

AUValue Kernel::getParameterValue(AUParameterAddress address) const noexcept {
  switch (address) {
    case ParameterAddressRate: return rate_.get();
    case ParameterAddressDepth: return depth_.get();
    case ParameterAddressDelay: return delay_.get();
    case ParameterAddressDry: return dryMix_.get();
    case ParameterAddressWet: return wetMix_.get();
    case ParameterAddressOdd90: return odd90_.get();
  }
  return 0.0;
}
