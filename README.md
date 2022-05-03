## LIBSSH2 for iOS and Mac OS X (Intel & Apple Silicon M1) - arm64 / x86_64

Supported version: 1.10.0.1

This repo provides a universal script for building static LIBSSH2 library for use in iOS and Mac OS X applications.
The actual library version is taken from https://github.com/libssh2/libssh2.git with tag 'libssh2-1.10.0'

## Building notes
1) The library is being built with OpenSSL backend. OpenSSL build scripts are being taken from https://github.com/apotocki/openssl-iosx and run with the help of 'pod' utility.
2) The library is being built with enabled ZLIB compression, that is available in system SDKs. 

## How to build?
 - Manually
```
    # clone the repo
    git clone -b 1.10.0 https://github.com/apotocki/libssh2-iosx
    
    # build libraries
    cd libssh2-iosx
    scripts/build.sh

    # have fun, the result artifacts will be located in 'frameworks' folder.
```    
 - Use cocoapods. Add the following lines into your project's Podfile:
```
    use_frameworks!
    pod 'libssh2-iosx', '~> 1.10.0.1' 
    # or optionally more precisely
    # pod 'libssh2-iosx', :git => 'https://github.com/apotocki/libssh2-iosx', :tag => '1.10.0.1'
```    
install new dependency:
```
   pod install --verbose
```

## As an advertisement…
Look at my iOS application on App Store, please:

[<table align="center" border=0 cellspacing=0 cellpadding=0><tr><td><img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70"/></td><td><a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br>HEX File Viewer & Editor</td><tr></table>]()

This app is designed for viewing and editing files at byte or character level.
  
You can support my open-source development by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

Feedbacks are also welcome!