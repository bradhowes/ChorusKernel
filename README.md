# Chorus Kernel

This is the code that generates a "chorus" effect for AUv3 audio units. Most of the DSP code is in C++ with the
rest in Swift and Object-C++. Note that there is no user interface included in this package. There are four
products contained in this package:

* Kernel -- the C++ kernel code
* KernelBridge -- the Objective-C++ code that provides an API for Swift access
* ParameterAddress -- an enum that defines the unique AUParameterAddress values for the runtime parameters used by the
kernel. Also contains definitions for creating nodes in an AUParameterTree.
* Parameters -- collection of the runtime parameters and an API for working with them. Also defines a `Configuration`
container that represents a specific set of parameter values that can be stored and recalled.

This package is currently used by the [SimplyChorus](https://github.com/bradhowes/SimplyChorus) and the 
[SoundFonts](https://github.com/bradhowes/SoundFonts) applications.
