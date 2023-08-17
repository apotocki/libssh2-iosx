#!/bin/bash
set -e
################## SETUP BEGIN
# brew install git git-lfs
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
LIBSSH2_VER=libssh2-1.11.0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
#XCODE_ROOT=$( xcode-select -print-path )
################## SETUP END
#MACSYSROOT=$XCODE_ROOT/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk

LIBSSH2_VER_NAME=${LIBSSH2_VER//./_}

if [[ -d $BUILD_DIR/frameworks ]]; then
	rm -rf $BUILD_DIR/frameworks
fi

if [[ ! -d $LIBSSH2_VER_NAME ]]; then
	echo downloading $LIBSSH2_VER ...
	git clone --depth 1 -b $LIBSSH2_VER https://github.com/libssh2/libssh2.git $LIBSSH2_VER_NAME
fi

############### OpenSSL
if [[ ! -d $SCRIPT_DIR/Pods/openssl-iosx/frameworks ]]; then
	if [[ ! -z "${OPENSSL_RELEASE_LINK}" ]]; then
		if [[ -d $SCRIPT_DIR/Pods/openssl-iosx ]]; then
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
############### OpenSSL

echo building $LIBSSH2_VER "(-j$THREAD_COUNT)" ...

if [ -d $BUILD_DIR/build ]; then
    rm -rf $BUILD_DIR/build
fi

generic_build()
{
if [[ ! -d $BUILD_DIR/build.$1.${2//;/_} ]]; then
	echo "BUILDING $1 $2"
	mkdir $BUILD_DIR/build
	pushd $BUILD_DIR/build

	cmake $4 -DCMAKE_OSX_ARCHITECTURES=$2 -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_INCLUDE_DIR="$OPENSSL_PATH/Headers" -DOPENSSL_SSL_LIBRARY="$OPENSSL_PATH/ssl.xcframework/$6/libssl.a" -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PATH/crypto.xcframework/$6/libcrypto.a" -DCMAKE_C_FLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32 $5" -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/frameworks -GXcode ../$LIBSSH2_VER_NAME

	cmake --build . --config Release --target libssh2_static -- $3 -j $THREAD_COUNT
	popd
	mv $BUILD_DIR/build $BUILD_DIR/build.$1.${2//;/_}
fi
}

generic_build ios arm64 "-sdk iphoneos" "-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=13.4" "-fembed-bitcode" "ios-arm64"
generic_build simulator "arm64;x86_64" "-sdk iphonesimulator" "-DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_DEPLOYMENT_TARGET=13.4 -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO -DCMAKE_IOS_INSTALL_COMBINED=YES" "-fembed-bitcode" "ios-*-simulator"
generic_build osx "arm64;x86_64" ""  "-DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO -DCMAKE_IOS_INSTALL_COMBINED=YES" "" "macos-*"

mkdir $BUILD_DIR/frameworks
xcodebuild -create-xcframework -library $BUILD_DIR/build.ios.arm64/src/Release-iphoneos/libssh2.a -library $BUILD_DIR/build.simulator.arm64_x86_64/src/Release-iphonesimulator/libssh2.a -library $BUILD_DIR/build.osx.arm64_x86_64/src/Release/libssh2.a -output $BUILD_DIR/frameworks/ssh2.xcframework

mkdir $BUILD_DIR/frameworks/Headers
cp $LIBSSH2_VER_NAME/include/*.h $BUILD_DIR/frameworks/Headers

