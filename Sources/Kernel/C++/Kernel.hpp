// Copyright © 2021 Brad Howes. All rights reserved.

#pragma once

#import <os/log.h>
#import <algorithm>
#import <string>
#import <AVFoundation/AVFoundation.h>

#import "DSPHeaders/BoolParameter.hpp"
#import "DSPHeaders/BusBuffers.hpp"
#import "DSPHeaders/DelayBuffer.hpp"
#import "DSPHeaders/EventProcessor.hpp"
#import "DSPHeaders/MillisecondsParameter.hpp"
#import "DSPHeaders/LFO.hpp"
#import "DSPHeaders/PercentageParameter.hpp"

/**
 The audio processing kernel that generates a "chorus" effect by combining an audio signal with a slightly delayed copy
 of itself. The delay value oscillates at a defined frequency which causes the delayed audio to vary in pitch due to it
 being sped up or slowed down.
 */
class Kernel : public DSPHeaders::EventProcessor<Kernel> {
public:
  using super = DSPHeaders::EventProcessor<Kernel>;
  friend super;

  /**
   Construct new kernel

   @param name the name to use for logging purposes.
   */
  Kernel(std::string name) noexcept : super(), name_{name}, log_{os_log_create(name_.c_str(), "Kernel")}
  {
    os_log_debug(log_, "constructor");
    lfo_.setWaveform(LFOWaveform::triangle);
  }

  /**
   Update kernel and buffers to support the given format and channel count

   @param busCount the number of busses to support
   @param format the audio format to render
   @param maxFramesToRender the maximum number of samples we will be asked to render in one go
   @param maxDelayMilliseconds the max number of milliseconds of audio samples to keep in delay buffer
   */
  void setRenderingFormat(NSInteger busCount, AVAudioFormat* format, AUAudioFrameCount maxFramesToRender,
                          double maxDelayMilliseconds) noexcept {
    super::setRenderingFormat(busCount, format, maxFramesToRender);
    initialize(format.channelCount, format.sampleRate, maxDelayMilliseconds);
  }

  /**
   Process an AU parameter value change by updating the kernel.

   @param address the address of the parameter that changed
   @param value the new value for the parameter
   @param rampDuration number of frames to ramp to the new value
   */
  void setParameterValue(AUParameterAddress address, AUValue value, AUAudioFrameCount rampDuration) noexcept;

  /**
   Obtain from the kernel the current value of an AU parameter.

   @param address the address of the parameter to return
   @returns current parameter value
   */
  AUValue getParameterValue(AUParameterAddress address) const noexcept;

private:
  using DelayLine = DSPHeaders::DelayBuffer<AUValue>;
  using LFO = DSPHeaders::LFO<AUValue>;

  void initialize(int channelCount, double sampleRate, double maxDelayMilliseconds) noexcept {
    samplesPerMillisecond_ = sampleRate / 1000.0;

    auto rate{rate_.get()};
    lfo_.setSampleRate(sampleRate);
    lfo_.setWaveform(LFOWaveform::sinusoid);
    lfo_.setFrequency(rate, 0.0);

    // Size of delay buffer needs to be twice the maxDelay value since at max delay and max depth settings, the bipolar
    // indices into the delay buffer will go from delay * -1 * depth to delay * 1 * depth (approximately).
    auto size = maxDelayMilliseconds * samplesPerMillisecond_ * 2.0 + 1;
    delayLines_.clear();
    for (auto index = 0; index < channelCount; ++index) {
      delayLines_.emplace_back(size, DelayLine::Interpolator::cubic4thOrder);
    }
  }

  void setRate(AUValue rate, AUAudioFrameCount rampingDuration) {
    rate_.set(rate, rampingDuration);
    lfo_.setFrequency(rate, rampingDuration);
  }

  void setParameterFromEvent(const AUParameterEvent& event) noexcept {
    setParameterValue(event.parameterAddress, event.value, event.rampDurationSampleFrames);
  }

  void doRenderingStateChanged(bool rendering) {
    if (!rendering) {
      rate_.stopRamping();
      depth_.stopRamping();
      delay_.stopRamping();
      dryMix_.stopRamping();
      wetMix_.stopRamping();
    }
  }

  void doRendering(NSInteger outputBusNumber, DSPHeaders::BusBuffers ins, DSPHeaders::BusBuffers outs,
                   AUAudioFrameCount frameCount) noexcept {
    auto odd90 = odd90_.get();

    // Generate frames -- note that in the ramping case, frameCount == 1
    for (; frameCount > 0; --frameCount) {

      // Nominal position of tap into delay line
      auto tap = delay_.frameValue();

      // Fraction of overall displacement available to move the tap
      auto displacementFraction = depth_.frameValue();
      assert(displacementFraction >= 0.0 && displacementFraction <= 1.0);

      // Displacement is the distance from the nominal tap to a non-zero min value.
      auto displacement = tap * displacementFraction;

      auto wetMix = wetMix_.frameValue();
      assert(wetMix >= 0.0 && wetMix <= 1.0);
      auto dryMix = dryMix_.frameValue();
      assert(dryMix >= 0.0 && dryMix <= 1.0);

      auto evenTap = lfo_.value() * displacement + tap;
      auto oddTap = lfo_.quadPhaseValue() * displacement + tap;
      lfo_.increment();

      // Generate samples for each channel
      for (int channel = 0; channel < ins.size(); ++channel) {
        auto inputSample = *ins[channel]++;
        auto delayedSample = delayLines_[channel].read(((channel & 1) && odd90) ? oddTap : evenTap);
        delayLines_[channel].write(inputSample);
        *outs[channel]++ = wetMix * delayedSample + dryMix * inputSample;
      }
    }
  }

  void doMIDIEvent(const AUMIDIEvent& midiEvent) noexcept {}

  DSPHeaders::Parameters::MillisecondsParameter<> rate_;
  DSPHeaders::Parameters::PercentageParameter<> depth_;
  DSPHeaders::Parameters::MillisecondsParameter<> delay_;
  DSPHeaders::Parameters::PercentageParameter<> dryMix_;
  DSPHeaders::Parameters::PercentageParameter<> wetMix_;
  DSPHeaders::Parameters::BoolParameter<> odd90_;

  double samplesPerMillisecond_;

  std::vector<DelayLine> delayLines_;
  LFO lfo_;
  AUAudioFrameCount rampRemaining_;
  std::string name_;
  os_log_t log_;
};
