## LIBSSH2 for iOS, visionOS, and Mac OS X (Intel & Apple Silicon M1) - arm64 / x86_64

Supported version: 1.11.0 (use the appropriate tag to select the version)

This repo provides a universal script for building static LIBSSH2 library for use in iOS, visionOS, and Mac OS X applications.
The actual library version is taken from https://github.com/libssh2/libssh2.git with the tag 'libssh2-1.11.0' 

## Prerequisites
  1) Xcode must be installed because xcodebuild is used to create xcframeworks
  2) ```xcode-select -p``` must point to Xcode app developer directory (by default e.g. /Applications/Xcode.app/Contents/Developer). If it points to CommandLineTools directory you should execute:
  ```sudo xcode-select --reset``` or ```sudo xcode-select -s /Applications/Xcode.app/Contents/Developer```
  3) CMake must be installed because it's used as the build system for LIBSSH2.
  4) Cocoapods must be installed because it's used to get the OpenSSL backend.
  5) For the creation of visionOS related artifacts and their integration into the resulting xcframeworks, XROS.platform and XRSimulator.platform should be available in the folder: /Applications/Xcode.app/Contents/Developer/Platforms

## Building notes
1) The library is built with OpenSSL backend. OpenSSL build scripts are taken from https://github.com/apotocki/openssl-iosx and run using the 'pod' utility.
2) The library is built with ZLIB compression enabled, which is available through the system SDKs.

## How to build?
 - Manually
```
    # clone the repo
    git clone -b 1.11.0 https://github.com/apotocki/libssh2-iosx
    
    # build libraries
    cd libssh2-iosx
    scripts/build.sh

    # have fun, the result artifacts will be located in 'frameworks' folder.
    # Then you can add the xcframework in your XCode project. The process is described, e.g., at https://www.simpleswiftguide.com/how-to-add-xcframework-to-xcode-project/
```    
 - Use cocoapods. Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'libssh2-iosx', '~> 1.11.0'
    # or optionally more precisely e.g.:
    # pod 'libssh2-iosx', :git => 'https://github.com/apotocki/libssh2-iosx', :tag => '1.11.0.1'
```
Then install new dependency:
```
   pod install --verbose
```

## As an advertisement…
Please check out my iOS application on the App Store:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

This application is designed to view and edit files at the byte or character level; calculate different hashes, encode/decode, and compress/decompress desired byte regions.
  
You can support my open-source development by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

Feedback is welcome!
