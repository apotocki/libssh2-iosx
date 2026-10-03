#!/bin/bash
set -euo pipefail

################## SETUP BEGIN
THREAD_COUNT=$(sysctl hw.ncpu | awk '{print $2}')
HOST_ARC=$( uname -m )
XCODE_ROOT=$( xcode-select -print-path )
LIBSSH2_VER=libssh2-1.11.1
# the openssl-iosx GitHub release whose XCFrameworks are linked as the crypto backend
OPENSSL_IOSX_VERSION=3.5.9.1
MACOSX_VERSION_ARM=12.3
MACOSX_VERSION_X86_64=10.13
IOS_VERSION=13.4
IOS_SIM_VERSION=13.4
CATALYST_VERSION=13.4
TVOS_VERSION=13.0
TVOS_SIM_VERSION=13.0
WATCHOS_VERSION=11.0
WATCHOS_SIM_VERSION=11.0
XROS_VERSION=1.0
XROS_SIM_VERSION=1.0
################## SETUP END

XROSSYSROOT=$XCODE_ROOT/Platforms/XROS.platform/Developer
XROSSIMSYSROOT=$XCODE_ROOT/Platforms/XRSimulator.platform/Developer
TVOSSYSROOT=$XCODE_ROOT/Platforms/AppleTVOS.platform/Developer
TVOSSIMSYSROOT=$XCODE_ROOT/Platforms/AppleTVSimulator.platform/Developer
WATCHOSSYSROOT=$XCODE_ROOT/Platforms/WatchOS.platform/Developer
WATCHOSSIMSYSROOT=$XCODE_ROOT/Platforms/WatchSimulator.platform/Developer

BUILD_PLATFORMS_ALL="macosx,macosx-arm64,macosx-x86_64,macosx-both,ios,iossim,iossim-arm64,iossim-x86_64,iossim-both,catalyst,catalyst-arm64,catalyst-x86_64,catalyst-both,xros,xrossim,xrossim-arm64,xrossim-x86_64,xrossim-both,tvos,tvossim,tvossim-both,tvossim-arm64,tvossim-x86_64,watchos,watchossim,watchossim-both,watchossim-arm64,watchossim-x86_64"

LIBSSH2_VER_NAME=${LIBSSH2_VER//./_}
BUILD_DIR="$( cd "$( dirname "./" )" >/dev/null 2>&1 && pwd )"

BUILD_PLATFORMS="macosx,ios,iossim,catalyst"
[[ -d $XROSSYSROOT/SDKs/XROS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xros"
[[ -d $XROSSIMSYSROOT/SDKs/XRSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim"
[[ -d $TVOSSYSROOT/SDKs/AppleTVOS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvos"
[[ -d $TVOSSIMSYSROOT/SDKs/AppleTVSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim"
[[ -d $WATCHOSSYSROOT/SDKs/WatchOS.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchos"
[[ -d $WATCHOSSIMSYSROOT/SDKs/WatchSimulator.sdk ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim-both"

REBUILD=false

# parse command line
for i in "$@"; do
  case $i in
    -p=*|--platforms=*)
      BUILD_PLATFORMS="${i#*=},"
      shift # past argument=value
      ;;
    --rebuild)
      REBUILD=true
      shift # past argument with no value
      ;;
    -*|--*)
      echo "Unknown option $i"
      exit 1
      ;;
    *)
      ;;
  esac
done

[[ "$BUILD_PLATFORMS" == *"macosx-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,macosx-arm64,macosx-x86_64"
[[ "$BUILD_PLATFORMS" == *"iossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,iossim-arm64,iossim-x86_64"
[[ "$BUILD_PLATFORMS" == *"catalyst-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,catalyst-arm64,catalyst-x86_64"
[[ "$BUILD_PLATFORMS" == *"xrossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim-arm64,xrossim-x86_64"
[[ "$BUILD_PLATFORMS" == *"tvossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim-arm64,tvossim-x86_64"
[[ "$BUILD_PLATFORMS" == *"watchossim-both"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim-arm64,watchossim-x86_64"
[[ "$BUILD_PLATFORMS," == *"macosx,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,macosx-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"iossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,iossim-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"catalyst,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,catalyst-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"xrossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,xrossim-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"tvossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,tvossim-$HOST_ARC"
[[ "$BUILD_PLATFORMS," == *"watchossim,"* ]] && BUILD_PLATFORMS="$BUILD_PLATFORMS,watchossim-$HOST_ARC"

BUILD_PLATFORMS=" ${BUILD_PLATFORMS//,/ } "

for i in $BUILD_PLATFORMS; do :;
if [[ ! ",$BUILD_PLATFORMS_ALL," == *",$i,"* ]]; then
    echo "Unknown platform '$i'"
    exit 1
fi
done

# An interrupted clone can leave a directory with .git but an incomplete work tree,
# so validate the files we need and clone into a temporary directory renamed on success.
if [[ ! -f $LIBSSH2_VER_NAME/CMakeLists.txt || ! -f $LIBSSH2_VER_NAME/include/libssh2.h ]]; then
    echo downloading $LIBSSH2_VER ...
    rm -rf $LIBSSH2_VER_NAME $LIBSSH2_VER_NAME.download
    git clone --depth 1 -b $LIBSSH2_VER https://github.com/libssh2/libssh2.git $LIBSSH2_VER_NAME.download
    mv $LIBSSH2_VER_NAME.download $LIBSSH2_VER_NAME
fi

############### OpenSSL Begin
# OpenSSL comes from openssl-iosx at the pinned tag, in one of three ways:
#   default               build it from source with the openssl-iosx build script
#   OPENSSL_DOWNLOAD=1    download the prebuilt XCFrameworks of that openssl-iosx GitHub release
#                         (OPENSSL_RELEASE_LINK overrides the release URL); used by CI and publication
#   OPENSSL_PATH=<dir>    use prepared frameworks: ssl.xcframework, crypto.xcframework and the
#                         headers inside crypto.xcframework slices or in Headers
if [[ -n "${OPENSSL_PATH:-}" ]]; then
    echo using OpenSSL from $OPENSSL_PATH
elif [[ "${OPENSSL_DOWNLOAD:-}" == "1" ]]; then
    OPENSSL_RELEASE_LINK=${OPENSSL_RELEASE_LINK:-https://github.com/apotocki/openssl-iosx/releases/download/$OPENSSL_IOSX_VERSION}
    OPENSSL_PATH=$BUILD_DIR/openssl-iosx-$OPENSSL_IOSX_VERSION-release
    if [[ ! -d $OPENSSL_PATH/ssl.xcframework || ! -d $OPENSSL_PATH/crypto.xcframework ]]; then
        echo downloading OpenSSL from $OPENSSL_RELEASE_LINK ...
        rm -rf $OPENSSL_PATH $OPENSSL_PATH.download
        mkdir -p $OPENSSL_PATH.download
        for archive in ssl.xcframework crypto.xcframework; do
            curl -fL $OPENSSL_RELEASE_LINK/$archive.zip -o $OPENSSL_PATH.download/$archive.zip
            unzip -q $OPENSSL_PATH.download/$archive.zip -d $OPENSSL_PATH.download
            rm $OPENSSL_PATH.download/$archive.zip
        done
        # releases before headers were packed into crypto.xcframework have them only in include.zip
        if ! ls -d $OPENSSL_PATH.download/crypto.xcframework/*/Headers/openssl >/dev/null 2>&1; then
            curl -fL $OPENSSL_RELEASE_LINK/include.zip -o $OPENSSL_PATH.download/include.zip
            unzip -q $OPENSSL_PATH.download/include.zip -d $OPENSSL_PATH.download
            rm $OPENSSL_PATH.download/include.zip
            mv $OPENSSL_PATH.download/include $OPENSSL_PATH.download/Headers
        fi
        mv $OPENSSL_PATH.download $OPENSSL_PATH
    fi
else
    OPENSSL_SOURCE=$BUILD_DIR/openssl-iosx-$OPENSSL_IOSX_VERSION
    if [[ ! -f $OPENSSL_SOURCE/scripts/build.sh ]]; then
        echo downloading openssl-iosx $OPENSSL_IOSX_VERSION build scripts ...
        rm -rf $OPENSSL_SOURCE $OPENSSL_SOURCE.download
        git clone --depth 1 -b $OPENSSL_IOSX_VERSION https://github.com/apotocki/openssl-iosx.git $OPENSSL_SOURCE.download
        mv $OPENSSL_SOURCE.download $OPENSSL_SOURCE
    fi
    # the openssl-iosx script keeps finished slices, so a repeated run only adds missing platforms
    OPENSSL_ARGS="-p=$(echo $BUILD_PLATFORMS | tr ' ' ',')"
    [[ $REBUILD == true ]] && OPENSSL_ARGS="$OPENSSL_ARGS --rebuild"
    echo building OpenSSL from source: openssl-iosx $OPENSSL_IOSX_VERSION $OPENSSL_ARGS ...
    (cd $OPENSSL_SOURCE && bash scripts/build.sh $OPENSSL_ARGS)
    OPENSSL_PATH=$OPENSSL_SOURCE/frameworks
fi

# (type): the OpenSSL XCFramework slice for a platform
openssl_slice()
{
    local pattern
    case $1 in
        macosx) pattern="macos-*" ;;
        catalyst) pattern="ios-*-maccatalyst" ;;
        iossim) pattern="ios-*-simulator" ;;
        xrossim) pattern="xros-*-simulator" ;;
        tvossim) pattern="tvos-*-simulator" ;;
        watchossim) pattern="watchos-*-simulator" ;;
        *) pattern="$1-arm64" ;;
    esac
    local slice=$(cd $OPENSSL_PATH/crypto.xcframework && ls -d $pattern 2>/dev/null | head -1)
    if [[ -z "$slice" ]]; then
        echo "OpenSSL has no slice for $1 in $OPENSSL_PATH" >&2
        exit 1
    fi
    echo $slice
}
############### OpenSSL End

COMMON_CFLAGS="-DOPENSSL_NO_ENGINE -Wno-shorten-64-to-32"

echo building $LIBSSH2_VER "(-j$THREAD_COUNT)" ...

# (type, arc, cmake args...)
generic_build()
{
    local type=$1 arc=$2
    shift 2
    local folder=$BUILD_DIR/build.$type.$arc
    if [[ $REBUILD == true ]] || [[ ! -f $folder.success ]] || [[ ! -f $folder/src/libssh2.a ]]; then
        [[ -f $folder.success ]] && rm $folder.success
        [[ -d $folder ]] && rm -rf $folder
        local slice
        slice=$(openssl_slice $type)
        # the headers of the slice itself when crypto.xcframework carries them
        local openssl_include=$OPENSSL_PATH/crypto.xcframework/$slice/Headers
        [[ -d $openssl_include/openssl ]] || openssl_include=$OPENSSL_PATH/Headers
        echo "building libssh2 ($type $arc) with OpenSSL from $slice..."
        cmake -S $BUILD_DIR/$LIBSSH2_VER_NAME -B $folder -G "Unix Makefiles" \
            -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON \
            -DBUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF -DENABLE_ZLIB_COMPRESSION=ON \
            -DCRYPTO_BACKEND=OpenSSL -DOPENSSL_ROOT_DIR="$OPENSSL_PATH" -DOPENSSL_USE_STATIC_LIBS=ON \
            -DOPENSSL_INCLUDE_DIR="$openssl_include" \
            -DOPENSSL_SSL_LIBRARY="$OPENSSL_PATH/ssl.xcframework/$slice/libssl.a" \
            -DOPENSSL_CRYPTO_LIBRARY="$OPENSSL_PATH/crypto.xcframework/$slice/libcrypto.a" \
            -DCMAKE_OSX_ARCHITECTURES=$arc "$@"
        cmake --build $folder --config Release --target libssh2_static -j $THREAD_COUNT
        touch $folder.success
    fi
}

# (type, arc, deployment-target, cmake args...): an Apple platform with its own CMake system name
apple_build()
{
    local type=$1 arc=$2 version=$3
    shift 3
    generic_build $type $arc -DCMAKE_OSX_DEPLOYMENT_TARGET=$version "-DCMAKE_C_FLAGS=$COMMON_CFLAGS" "$@"
}

build_libs()
{
    [[ -d $BUILD_DIR/build.$1 ]] && rm -rf $BUILD_DIR/build.$1
    mkdir -p $BUILD_DIR/build.$1

    if [[ "$BUILD_PLATFORMS" == *$1-arm64* ]]; then
        if [[ "$BUILD_PLATFORMS" == *$1-x86_64* ]]; then
            lipo -create $BUILD_DIR/build.$1.arm64/src/libssh2.a $BUILD_DIR/build.$1.x86_64/src/libssh2.a -output $BUILD_DIR/build.$1/libssh2.a
        else
            cp $BUILD_DIR/build.$1.arm64/src/libssh2.a $BUILD_DIR/build.$1/
        fi
    elif [[ "$BUILD_PLATFORMS" == *$1-x86_64* ]]; then
        cp $BUILD_DIR/build.$1.x86_64/src/libssh2.a $BUILD_DIR/build.$1/
    fi
}

# (type, system name, sdk, deployment target)
generic_double_build()
{
    [[ "$BUILD_PLATFORMS" == *$1-arm64* ]] && apple_build $1 arm64 $4 -DCMAKE_SYSTEM_NAME=$2 -DCMAKE_OSX_SYSROOT=$3
    [[ "$BUILD_PLATFORMS" == *$1-x86_64* ]] && apple_build $1 x86_64 $4 -DCMAKE_SYSTEM_NAME=$2 -DCMAKE_OSX_SYSROOT=$3
    build_libs $1
}

build_macosx_libs()
{
    [[ "$BUILD_PLATFORMS" == *macosx-arm64* ]] && apple_build macosx arm64 $MACOSX_VERSION_ARM -DCMAKE_OSX_SYSROOT=macosx
    [[ "$BUILD_PLATFORMS" == *macosx-x86_64* ]] && apple_build macosx x86_64 $MACOSX_VERSION_X86_64 -DCMAKE_OSX_SYSROOT=macosx
    build_libs macosx
}

build_catalyst_libs()
{
    [[ "$BUILD_PLATFORMS" == *catalyst-arm64* ]] && generic_build catalyst arm64 -DCMAKE_OSX_SYSROOT=macosx "-DCMAKE_C_FLAGS=-target arm64-apple-ios$CATALYST_VERSION-macabi $COMMON_CFLAGS"
    [[ "$BUILD_PLATFORMS" == *catalyst-x86_64* ]] && generic_build catalyst x86_64 -DCMAKE_OSX_SYSROOT=macosx "-DCMAKE_C_FLAGS=-target x86_64-apple-ios$CATALYST_VERSION-macabi $COMMON_CFLAGS"
    build_libs catalyst
}

[[ "$BUILD_PLATFORMS" == *macosx* ]] && build_macosx_libs
[[ "$BUILD_PLATFORMS" == *catalyst* ]] && build_catalyst_libs
[[ "$BUILD_PLATFORMS" == *iossim* ]] && generic_double_build iossim iOS iphonesimulator $IOS_SIM_VERSION
[[ "$BUILD_PLATFORMS" == *xrossim* ]] && generic_double_build xrossim visionOS xrsimulator $XROS_SIM_VERSION
[[ "$BUILD_PLATFORMS" == *tvossim* ]] && generic_double_build tvossim tvOS appletvsimulator $TVOS_SIM_VERSION
[[ "$BUILD_PLATFORMS" == *watchossim* ]] && generic_double_build watchossim watchOS watchsimulator $WATCHOS_SIM_VERSION

[[ "$BUILD_PLATFORMS" == *"ios "* ]] && apple_build ios arm64 $IOS_VERSION -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT=iphoneos
[[ "$BUILD_PLATFORMS" == *"xros "* ]] && apple_build xros arm64 $XROS_VERSION -DCMAKE_SYSTEM_NAME=visionOS -DCMAKE_OSX_SYSROOT=xros
[[ "$BUILD_PLATFORMS" == *"tvos "* ]] && apple_build tvos arm64 $TVOS_VERSION -DCMAKE_SYSTEM_NAME=tvOS -DCMAKE_OSX_SYSROOT=appletvos
[[ "$BUILD_PLATFORMS" == *"watchos "* ]] && apple_build watchos arm64 $WATCHOS_VERSION -DCMAKE_SYSTEM_NAME=watchOS -DCMAKE_OSX_SYSROOT=watchos

LIBARGS=
[[ "$BUILD_PLATFORMS" == *macosx* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.macosx/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *catalyst* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.catalyst/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *iossim* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.iossim/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *xrossim* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.xrossim/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *tvossim* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.tvossim/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *watchossim* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.watchossim/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *"ios "* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.ios.arm64/src/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *"xros "* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.xros.arm64/src/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *"tvos "* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.tvos.arm64/src/libssh2.a -headers $BUILD_DIR/frameworks/Headers"
[[ "$BUILD_PLATFORMS" == *"watchos "* ]] && LIBARGS="$LIBARGS -library $BUILD_DIR/build.watchos.arm64/src/libssh2.a -headers $BUILD_DIR/frameworks/Headers"

[[ -d $BUILD_DIR/frameworks ]] && rm -rf $BUILD_DIR/frameworks
mkdir -p $BUILD_DIR/frameworks/Headers
cp $LIBSSH2_VER_NAME/include/*.h $BUILD_DIR/frameworks/Headers/
xcodebuild -create-xcframework $LIBARGS -output $BUILD_DIR/frameworks/ssh2.xcframework
