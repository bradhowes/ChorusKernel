#import "C++/Kernel.hpp"

// This must be done in a source file -- include files cannot see the Swift bridging file which contains the definition
// of ParameterAddress.

@import ParameterAddress;

AUAudioFrameCount Kernel::setRampedParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount duration) noexcept {
  switch (address) {
    case ParameterAddressRate: setRate(value, duration); return duration;
    case ParameterAddressDepth: depth_.set(value, duration); return duration;
    case ParameterAddressDelay: delay_.set(value, duration); return duration;
    case ParameterAddressDry: dryMix_.set(value, duration); return duration;
    case ParameterAddressWet: wetMix_.set(value, duration); return duration;
    case ParameterAddressOdd90: odd90_.set(value, duration); return 0;
  }
  return 0;
}

void Kernel::setParameterValuePending(AUParameterAddress address, AUValue value) noexcept {
  switch (address) {
    case ParameterAddressRate: rate_.setPending(value); break;
    case ParameterAddressDepth: depth_.setPending(value); break;
    case ParameterAddressDelay: delay_.setPending(value); break;
    case ParameterAddressDry: dryMix_.setPending(value); break;
    case ParameterAddressWet: wetMix_.setPending(value); break;
    case ParameterAddressOdd90: odd90_.setPending(value); break;
  }
  return 0;
}

AUValue Kernel::getParameterValuePending(AUParameterAddress address) const noexcept {
  switch (address) {
    case ParameterAddressRate: return rate_.getPending();
    case ParameterAddressDepth: return depth_.getPending();
    case ParameterAddressDelay: return delay_.getPending();
    case ParameterAddressDry: return dryMix_.getPending();
    case ParameterAddressWet: return wetMix_.getPending();
    case ParameterAddressOdd90: return odd90_.getPending();
  }
  return 0.0;
}
