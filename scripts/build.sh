#!/bin/bash
set -e
################## SETUP BEGIN
# brew install git git-lfs
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
LIBSSH2_VER=libssh2-1.10.0
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"
################## SETUP END
LIBSSH2_VER_NAME=${LIBSSH2_VER//./_}

if [ ! -d $BUILD_DIR/frameworks ]; then

if [ ! -d $LIBSSH2_VER_NAME ]; then
	echo downloading $LIBSSH2_VER ...
	git clone --depth 1 -b $LIBSSH2_VER https://github.com/libssh2/libssh2.git $LIBSSH2_VER_NAME
fi

############### OpenSSL
if [ ! -d $SCRIPT_DIR/Pods/openssl-iosx/frameworks ]; then
	pushd $SCRIPT_DIR
	pod install --verbose
	popd
fi
OPENSSL_PATH=$SCRIPT_DIR/Pods/openssl-iosx/frameworks
############### OpenSSL

echo building $LIBSSH2_VER "(-j$THREAD_COUNT)" ...

if [ -d $BUILD_DIR/build ]; then
    rm -rf $BUILD_DIR/build
fi

if [ ! -d $BUILD_DIR/build.ios ]; then
    
mkdir $BUILD_DIR/build
pushd $BUILD_DIR/build

cmake -DCMAKE_TOOLCHAIN_FILE=$SCRIPT_DIR/ios.toolchain.cmake -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_INCLUDE_DIR="$OPENSSL_PATH/Headers" -DOPENSSL_SSL_LIBRARY="$OPENSSL_PATH/ssl.xcframework/ios-arm64/libssl.a" -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PATH/crypto.xcframework/ios-arm64/libcrypto.a" -DCMAKE_C_FLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32 -fembed-bitcode-marker" -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$BUILD_DIR/frameworks -GXcode ../$LIBSSH2_VER_NAME

cmake --build . --config Release --target libssh2 -- -sdk iphoneos -j $THREAD_COUNT
popd
mv $BUILD_DIR/build $BUILD_DIR/build.ios
fi

if [ ! -d $BUILD_DIR/build.iossim ]; then

mkdir $BUILD_DIR/build
pushd $BUILD_DIR/build

cmake  -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_INCLUDE_DIR="$OPENSSL_PATH/Headers" -DOPENSSL_SSL_LIBRARY="$OPENSSL_PATH/ssl.xcframework/ios-$HOST_ARC-simulator/libssl.a" -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PATH/crypto.xcframework/ios-$HOST_ARC-simulator/libcrypto.a" -DCMAKE_C_FLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32 -fembed-bitcode-marker" -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -GXcode ../$LIBSSH2_VER_NAME

cmake --build . --config Release --target libssh2 -- -sdk iphonesimulator -j $THREAD_COUNT
popd
mv $BUILD_DIR/build $BUILD_DIR/build.iossim
fi

if [ ! -d $BUILD_DIR/build.osx ]; then

mkdir $BUILD_DIR/build
pushd $BUILD_DIR/build

cmake  -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_INCLUDE_DIR="$OPENSSL_PATH/Headers" -DOPENSSL_SSL_LIBRARY="$OPENSSL_PATH/ssl.xcframework/macos-$HOST_ARC/libssl.a" -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PATH/crypto.xcframework/macos-$HOST_ARC/libcrypto.a" -DCMAKE_C_FLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32" -DENABLE_ZLIB_COMPRESSION=ON -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -GXcode ../$LIBSSH2_VER_NAME

cmake --build . --config Release --target libssh2 -- -j $THREAD_COUNT
popd
mv $BUILD_DIR/build $BUILD_DIR/build.osx
fi

mkdir $BUILD_DIR/frameworks
xcodebuild -create-xcframework -library $BUILD_DIR/build.ios/src/Release-iphoneos/libssh2.a -library $BUILD_DIR/build.iossim/src/Release-iphonesimulator/libssh2.a -library $BUILD_DIR/build.osx/src/Release/libssh2.a -output $BUILD_DIR/frameworks/ssh2.xcframework

mkdir $BUILD_DIR/frameworks/Headers
cp $LIBSSH2_VER_NAME/include/*.h $BUILD_DIR/frameworks/Headers
fi
#--debug-output
#cmake -DCMAKE_TOOLCHAIN_FILE=$TPLS_HOME/../projects/cmake/ios.toolchain.cmake -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR="$TPLS_HOME/openssl" -DOPENSSL_INCLUDE_DIR="$TPLS_HOME/openssl/include" -DOPENSSL_SSL_LIBRARY="$TPLS_HOME/openssl/lib.ios/libssl.a" -DOPENSSL_CRYPTO_LIBRARY="$TPLS_HOME/openssl/lib.ios/libcrypto.a" -DCMAKE_C_FLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32 -fembed-bitcode-marker" -DENABLE_ZLIB_COMPRESSION=ON -DZLIB_LIBRARY=$TPLS_HOME/zlib -DBUILD_SHARED_LIBS=OFF -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$TPLS_HOME/libssh2 -GXcode ../$LIBSSH2_VER_NAME.src

#
#cmake --build . --config Release --target install -- -sdk iphonesimulator



#xcrun lipo -create src/Release-iphonesimulator/libssh2.a src/Release-iphoneos/libssh2.a -o $TPLS_HOME/libssh2/lib.ios/libssh2.a
#mkdir $BUILD_DIR/frameworks

#mv $BUILD_DIR/build/include $BUILD_DIR/frameworks/Headers

#xcodebuild -create-xcframework -library $BUILD_DIR/build/lib/libssl.a -library $BUILD_DIR/build/lib.iossim/libssl.a -library $BUILD_DIR/build/lib.ios/libssl.a -output $BUILD_DIR/frameworks/ssl.xcframework

