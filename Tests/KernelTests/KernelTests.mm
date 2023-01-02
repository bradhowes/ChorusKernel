// Copyright © 2021 Brad Howes. All rights reserved.

#import <XCTest/XCTest.h>
#import <cmath>

#import "../../Sources/Kernel/C++/Kernel.hpp"

@import ParameterAddress;

@interface KernelTests : XCTestCase
@property float epsilon;
@end

@implementation KernelTests

- (void)setUp {
  _epsilon = 1.0e-5;
}

- (void)tearDown {
}

- (void)testKernelParams {
  Kernel* kernel = new Kernel("blah");
  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  kernel->setRenderingFormat(1, format, 100, 20.0);

  kernel->setParameterValue(ParameterAddressDepth, 13.5, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressDepth), 13.5, _epsilon);

  kernel->setParameterValue(ParameterAddressRate, 30.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressRate), 30.0, _epsilon);

  kernel->setParameterValue(ParameterAddressDelay, 20.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressDelay), 20.0, _epsilon);

  kernel->setParameterValue(ParameterAddressDry, 50.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressDry), 50.0, _epsilon);

  kernel->setParameterValue(ParameterAddressWet, 60.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressWet), 60.0, _epsilon);

  kernel->setParameterValue(ParameterAddressOdd90, 0.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressOdd90), 0.0, _epsilon);
  kernel->setParameterValue(ParameterAddressOdd90, 1.0, 0);
  XCTAssertEqualWithAccuracy(kernel->getParameterValue(ParameterAddressOdd90), 1.0, _epsilon);
}

- (void)testRendering {
  AudioTimeStamp timestamp = AudioTimeStamp();
  AudioUnitRenderActionFlags flags = 0;
  AUAudioUnitStatus (^mockPullInput)(AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *timestamp,
                                     AUAudioFrameCount frameCount, NSInteger inputBusNumber,
                                     AudioBufferList *inputData);
  mockPullInput = ^(AudioUnitRenderActionFlags *actionFlags, const AudioTimeStamp *timestamp,
                    AUAudioFrameCount frameCount, NSInteger inputBusNumber, AudioBufferList *inputData) {
    auto bufferCount = inputData->mNumberBuffers;
    for (int index = 0; index < bufferCount; ++index) {
      auto& buffer = inputData->mBuffers[index];
      auto numberOfChannels = buffer.mNumberChannels;
      assert(numberOfChannels == 1); // not interleaved
      auto bufferSize = buffer.mDataByteSize;
      assert(sizeof(AUValue) * frameCount == bufferSize);
      auto ptr = reinterpret_cast<AUValue*>(buffer.mData);
      for (int pos = 0; pos < frameCount; ++pos) {
        ptr[pos] = AUValue(pos) / (frameCount - 1);
      }
    }

    return 0;
  };

  AUAudioFrameCount maxFrames = 512;

  auto kernel = Kernel("blah");

  AVAudioFormat* format = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100.0 channels:2];
  kernel.setRenderingFormat(1, format, 512, 50.0);

  kernel.setParameterValue(ParameterAddressDepth, 13.5, 0);
  kernel.setParameterValue(ParameterAddressRate, 15.0, 0);
  kernel.setParameterValue(ParameterAddressDelay, 50.0, 0);
  kernel.setParameterValue(ParameterAddressDry, 50.0, 0);
  kernel.setParameterValue(ParameterAddressWet, 50.0, 0);
  kernel.setParameterValue(ParameterAddressOdd90, 0.0, 0);

  AUAudioFrameCount frames = maxFrames;
  AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:format frameCapacity:maxFrames];
  auto status = kernel.processAndRender(&timestamp, frames, 0, [buffer mutableAudioBufferList], nil, mockPullInput);
  XCTAssertEqual(status, 0);

  auto ptr = buffer.floatChannelData[0];
  XCTAssertEqualWithAccuracy(ptr[0], 0.0, _epsilon);
  XCTAssertEqualWithAccuracy(ptr[1], 0.000978, _epsilon);
  XCTAssertEqualWithAccuracy(ptr[2], 0.001957, _epsilon);
  XCTAssertEqualWithAccuracy(ptr[3], 0.002935, _epsilon);
  XCTAssertEqualWithAccuracy(ptr[4], 0.003914, _epsilon);
  XCTAssertEqualWithAccuracy(ptr[frames-1], 0.944233, _epsilon);
}

@end
