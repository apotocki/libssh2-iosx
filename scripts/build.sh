#!/bin/bash
set -e
################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
XCODE_ROOT=$( xcode-select -print-path )
LIBSSH2_VER=libssh2-1.11.0
#MACOSX_VERSION_ARM=11
#MACOSX_VERSION_X86_64=11
IOS_VERSION=13.4
IOS_SIM_VERSION=13.4
################## SETUP END

IOSSYSROOT=$XCODE_ROOT/Platforms/iPhoneOS.platform/Developer
IOSSIMSYSROOT=$XCODE_ROOT/Platforms/iPhoneSimulator.platform/Developer
MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer
XROSSYSROOT=$XCODE_ROOT/Platforms/XROS.platform/Developer
XROSSIMSYSROOT=$XCODE_ROOT/Platforms/XRSimulator.platform/Developer

LIBSSH2_VER_NAME=${LIBSSH2_VER//./_}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"

MACOSX_VERSION_X86_64_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_X86_64}" ] && MACOSX_VERSION_X86_64_BUILD_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_VERSION_X86_64"
MACOSX_VERSION_ARM_BUILD_FLAGS="" && [ ! -z "${MACOSX_VERSION_ARM}" ] && MACOSX_VERSION_ARM_BUILD_FLAGS="-DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_VERSION_ARM"

if [ $(clang++ --version | head -1 | sed -E 's/([a-zA-Z ]+)([0-9]+).*/\2/') -gt 14 ]; then
	CLANG15=true
fi


if [ -d $BUILD_DIR/frameworks ]; then
	rm -rf $BUILD_DIR/frameworks
fi

if [ ! -d $LIBSSH2_VER_NAME ]; then
	echo downloading $LIBSSH2_VER ...
	git clone --depth 1 -b $LIBSSH2_VER https://github.com/libssh2/libssh2.git $LIBSSH2_VER_NAME
fi

############### OpenSSL Begin
if [ ! -d $SCRIPT_DIR/Pods/openssl-iosx/frameworks ]; then
	if [ ! -z "${OPENSSL_RELEASE_LINK}" ]; then
		if [ -d $SCRIPT_DIR/Pods/openssl-iosx ]; then
			rm -rf $SCRIPT_DIR/Pods/openssl-iosx
		fi
		mkdir -p $SCRIPT_DIR/Pods/openssl-iosx
		pushd $SCRIPT_DIR/Pods/openssl-iosx
		curl -L ${OPENSSL_RELEASE_LINK}/include.zip -o $SCRIPT_DIR/Pods/openssl-iosx/include.zip
		curl -L ${OPENSSL_RELEASE_LINK}/crypto.xcframework.zip -o $SCRIPT_DIR/Pods/openssl-iosx/crypto.xcframework.zip
		curl -L ${OPENSSL_RELEASE_LINK}/ssl.xcframework.zip -o $SCRIPT_DIR/Pods/openssl-iosx/ssl.xcframework.zip
		unzip -q include.zip
		unzip -q crypto.xcframework.zip
		unzip -q ssl.xcframework.zip
		mkdir frameworks
		mv include frameworks/Headers
		mv crypto.xcframework frameworks/
		mv ssl.xcframework frameworks/
		popd
	else
		pushd $SCRIPT_DIR
		pod repo update
		pod install --verbose
		popd
	fi
fi
OPENSSL_PATH=$SCRIPT_DIR/Pods/openssl-iosx/frameworks
############### OpenSSL End

echo building $LIBSSH2_VER "(-j$THREAD_COUNT)" ...

if [ -d $BUILD_DIR/build ]; then
    rm -rf $BUILD_DIR/build
fi

generic_build()
{
if [ ! -d $BUILD_DIR/build.$1.${2//;/_} ]; then
	echo "BUILDING $1 $2"
	mkdir $BUILD_DIR/build
	pushd $BUILD_DIR/build

	cmake $4 -DCMAKE_OSX_ARCHITECTURES=$2 -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_INCLUDE_DIR="$OPENSSL_PATH/Headers" -DOPENSSL_SSL_LIBRARY="$OPENSSL_PATH/ssl.xcframework/$6/libssl.a" -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PATH/crypto.xcframework/$6/libcrypto.a" -DCMAKE_C_FLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32 $5" -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/frameworks -GXcode ../$LIBSSH2_VER_NAME

	cmake --build . --config Release --target libssh2_static -- $3 -j $THREAD_COUNT
	popd
	mv $BUILD_DIR/build $BUILD_DIR/build.$1.${2//;/_}
fi
}

generic_build ios arm64 "-sdk iphoneos" "-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$IOS_VERSION" "-fembed-bitcode" "ios-arm64"
generic_build ios-simulator "arm64;x86_64" "-sdk iphonesimulator" "-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=$IOS_SIM_VERSION -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO" "-fembed-bitcode" "ios-*-simulator"
generic_build osx "arm64" "" "$MACOSX_VERSION_ARM_BUILD_FLAGS -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO" "" "macos-*"
generic_build osx "x86_64" "" "$MACOSX_VERSION_X86_64_BUILD_FLAGS -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO" "" "macos-*"

if [ ! -d $BUILD_DIR/build.osx.arm64_x86_64 ]; then
    mkdir -p $BUILD_DIR/build.osx.arm64_x86_64/src/Release
    lipo -create $BUILD_DIR/build.osx.arm64/src/Release/libssh2.a $BUILD_DIR/build.osx.x86_64/src/Release/libssh2.a -output $BUILD_DIR/build.osx.arm64_x86_64/src/Release/libssh2.a
fi

if [ -d $XROSSYSROOT ]; then
    generic_build xros arm64 "-sdk xros" "-DCMAKE_SYSTEM_NAME=visionOS" "-fembed-bitcode" "xros-arm64"
fi

if [ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]; then
    generic_build xros-simulator "arm64;x86_64" "-sdk xrsimulator" "-DCMAKE_SYSTEM_NAME=iOS  -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO" "-fembed-bitcode" "xros-*-simulator"
fi


LIBARGS="-library $BUILD_DIR/build.ios.arm64/src/Release-iphoneos/libssh2.a \
    -library $BUILD_DIR/build.ios-simulator.arm64_x86_64/src/Release-iphonesimulator/libssh2.a \
    -library $BUILD_DIR/build.osx.arm64_x86_64/src/Release/libssh2.a"

if [ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]; then
    LIBARGS="$LIBARGS -library $BUILD_DIR/build.xros-simulator.arm64_x86_64/src/Release-xrsimulator/libssh2.a"
fi
if [ -d $XROSSYSROOT/SDKs/XROS.sdk ]; then
    LIBARGS="$LIBARGS -library $BUILD_DIR/build.xros.arm64/src/Release-xros/libssh2.a"
fi
xcodebuild -create-xcframework $LIBARGS -output $BUILD_DIR/frameworks/ssh2.xcframework

mkdir $BUILD_DIR/frameworks/Headers
cp $LIBSSH2_VER_NAME/include/*.h $BUILD_DIR/frameworks/Headers
