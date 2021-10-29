## LIBSSH2 for iOS and Mac OS X - arm64 / x86_64

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
    git clone -b 1.10.0.1 https://github.com/apotocki/libssh2-iosx
    
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
    # pod 'libssh2-iosx', :git => 'https://github.com/apotocki/libssh2-iosx', :tag => '~> 1.10.0.1'
```    
install new dependency:
```
   pod install --verbose
```
