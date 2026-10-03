# libssh2-iosx

## Overview

`libssh2-iosx` is a build and distribution project that produces the **libssh2 static library packaged as an XCFramework** for Apple platforms.

This repository **does not contain libssh2 source code**. The source code is fetched from the official upstream repository:

[https://github.com/libssh2/libssh2](https://github.com/libssh2/libssh2)

using the corresponding upstream tag (for example `libssh2-1.11.1`).

---

## Supported libssh2 Versions

Supported libssh2 1.11.x upstream versions: [1.11.1](https://github.com/apotocki/libssh2-iosx/tree/1.11.1.0), [1.11.0](https://github.com/apotocki/libssh2-iosx/tree/1.11.0.1)

Supported libssh2 1.10.x upstream versions: [1.10.0](https://github.com/apotocki/libssh2-iosx/tree/1.10.0.2)

Supported libssh2 1.9.x upstream versions: [1.9.0](https://github.com/apotocki/libssh2-iosx/tree/1.9.0.1)


Use the appropriate **Git tag or branch** to select the desired libssh2 version.

### Versioning Policy

Branches correspond to official libssh2 versions.
Tags use the format `<libssh2_version>.<package_patch>` (e.g. `1.11.1.0`), where `package_patch` is this repository’s packaging/build revision for that upstream version.

---

## Supported Platforms

libssh2 is built for:

* iOS / iOS Simulator
* watchOS / watchOS Simulator
* tvOS / tvOS Simulator
* visionOS / visionOS Simulator
* macOS
* Mac Catalyst

Both Intel (`x86_64`) and Apple Silicon (`arm64`) architectures are supported where applicable.

---

## Prerequisites

1. **Install Xcode**
   Xcode is required because `xcodebuild` is used to create XCFrameworks.

2. **Verify Xcode Developer Directory**
   The `xcode-select -p` command must point to the Xcode developer directory (for example `/Applications/Xcode.app/Contents/Developer`).
   If it points to the Command Line Tools directory, reset it using one of the following commands:

   ```bash
   sudo xcode-select --reset
   ```
   or

   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

3. **Install CMake**
   CMake 3.20 or newer is required (for example `brew install cmake`).

4. **Install Required SDKs**
   To build for tvOS, watchOS, visionOS, and their simulators, make sure the corresponding SDKs are installed in:

   ```
   /Applications/Xcode.app/Contents/Developer/Platforms
   ```

---

## Build Manually

```bash
# clone the repository
git clone https://github.com/apotocki/libssh2-iosx

# build libraries
cd libssh2-iosx
scripts/build.sh

# build artifacts will be located in the `frameworks` directory
```

---

## Selecting Platforms and Architectures

Running `build.sh` without arguments builds the XCFramework for iOS, macOS, and Catalyst. If the corresponding SDKs are installed, it also builds for watchOS, tvOS, visionOS, and all available simulators.

The simulator architecture (`arm64` or `x86_64`) is selected automatically based on the host system.

To build a specific set of platforms and architectures, use the `-p` option. For example:

```bash
scripts/build.sh -p=ios,iossim-x86_64
# builds the XCFramework only for iOS devices and iOS Simulator (x86_64)
```

Supported values for the `-p` option:

```text
macosx,macosx-arm64,macosx-x86_64,macosx-both,
ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,
catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,
xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,
tvos,tvossim,tvossim-arm64,tvossim-x86_64,tvossim-both,
watchos,watchossim,watchossim-arm64,watchossim-x86_64,watchossim-both
```

The `-both` suffix builds for both `arm64` and `x86_64` architectures. Platform names without an architecture suffix (for example `macosx`, `iossim`) build only for the current host architecture.

---

## Rebuild Option

To force a clean rebuild without reusing artifacts from previous builds, use the `--rebuild` option:

```bash
scripts/build.sh -p=ios,iossim-x86_64 --rebuild
```

---

## OpenSSL Backend

libssh2 is built with the OpenSSL crypto backend and zlib compression (zlib comes from the system SDKs). It is compiled against [openssl-iosx](https://github.com/apotocki/openssl-iosx) 3.5.9.1 (`OPENSSL_IOSX_VERSION` in `scripts/build.sh`). The OpenSSL code itself is not inside `ssh2.xcframework`: your application links OpenSSL, which must be a compatible OpenSSL 3.5 or a newer 3.x release.

By default, `scripts/build.sh` (also when run by `pod install`) builds OpenSSL **from source** with the openssl-iosx build scripts; no prebuilt binaries are downloaded. To use prebuilt OpenSSL instead, opt in explicitly:

```bash
# download the prebuilt XCFrameworks of the pinned openssl-iosx GitHub release
OPENSSL_DOWNLOAD=1 scripts/build.sh
# the same from another release
OPENSSL_DOWNLOAD=1 OPENSSL_RELEASE_LINK=https://github.com/apotocki/openssl-iosx/releases/download/<tag> scripts/build.sh
# a local folder with ssl.xcframework and crypto.xcframework (headers inside crypto.xcframework or in Headers)
OPENSSL_PATH=/path/to/openssl-iosx/frameworks scripts/build.sh
```

The GitHub Actions workflow of this repository and the CocoaPods Trunk publication use `OPENSSL_DOWNLOAD=1` to save build time.

---

## Build Using CocoaPods

Add the following to your `Podfile`:

```ruby
use_frameworks!
pod 'libssh2-iosx', '~> 1.11.1'
# or pin to a specific tag
# pod 'libssh2-iosx', :git => 'https://github.com/apotocki/libssh2-iosx', :tag => '1.11.1.0'
```

By default, the pod also installs a compatible OpenSSL: it depends on `openssl-iosx` `~> 3.5` (the `libssh2-iosx/OpenSSL` subspec), so nothing else is needed.

If your project already gets OpenSSL another way (for example a different OpenSSL pod or your own build), use the `Core` subspec, which contains only libssh2. Two OpenSSL copies in one application cause duplicate symbol errors, and the OpenSSL you link must be compatible with OpenSSL 3.5:

```ruby
pod 'libssh2-iosx/Core', '~> 1.11.1'
```

Then install the dependency:

```bash
pod install --verbose
```

---

## Contributions

Build outputs in this repository are generated from internal templates, so pull requests that directly modify generated files cannot be accepted. Please use **GitHub Issues** to report build problems or discuss changes, and include the libssh2 version, target platform(s), and build command.

---

## License

This repository contains build scripts for libssh2.

Precompiled artifacts published via GitHub Releases are subject to the upstream libssh2 license terms: libssh2 is distributed under the BSD 3-Clause license. They link OpenSSL, which is subject to its own license.

---

## As an advertisement…

Please check out my iOS application on the App Store:

<table align="center" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td>
      <a href="https://apps.apple.com/us/app/potohex/id1620963302">
        <img src="https://is4-ssl.mzstatic.com/image/thumb/Purple112/v4/78/d6/f8/78d6f802-78f6-267a-8018-751111f52c10/AppIcon-0-1x_U007emarketing-0-10-0-85-220.png/460x0w.webp" width="70" />
      </a>
    </td>
    <td>
      <a href="https://apps.apple.com/us/app/potohex/id1620963302">PotoHEX</a><br />
      HEX File Viewer &amp; Editor
    </td>
  </tr>
</table>

PotoHEX is designed for viewing and editing files at the byte or character level, calculating hashes, encoding/decoding data, and compressing/decompressing selected byte ranges.

If you find this project useful, you can support my open-source work by trying the [App](https://apps.apple.com/us/app/potohex/id1620963302).

---

Feedback is welcome!
