#!/usr/bin/env bash
# Usage: ANDROID_NDK_HOME=/path/to/ndk NXEMU_BUILD_JOBS=4 ./build_android_arm64.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${FFMPEG_BUILD_DIR:-${TMPDIR:-/tmp}/nxemu-ffmpeg-android-7.0.3}"
OUTPUT_DIR="$SCRIPT_DIR/lib/arm64-v8a"
case "$(uname -s)" in
    Darwin) HOST_TAG=darwin-x86_64 ;;
    Linux) HOST_TAG=linux-x86_64 ;;
    *) echo 'Build Android archives on macOS or Linux.' >&2; exit 1 ;;
esac
TOOLCHAIN="${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/$HOST_TAG/bin"
CC="$TOOLCHAIN/aarch64-linux-android28-clang"
test -x "$CC"
mkdir -p "$BUILD_DIR"
BUILD_DIR="$(cd "$BUILD_DIR" && pwd)"
ARCHIVE="${FFMPEG_ARCHIVE:-$BUILD_DIR/ffmpeg-7.0.3.tar.xz}"
if [ ! -f "$ARCHIVE" ]; then curl -fL https://ffmpeg.org/releases/ffmpeg-7.0.3.tar.xz -o "$ARCHIVE"; fi
if command -v sha256sum >/dev/null; then HASH_TOOL=sha256sum; else HASH_TOOL='shasum -a 256'; fi
EXPECTED_HASH=bbb18f3cc5c1c34b21cf176c0168c4d9aa97697542a97f60d491a58a814dea65
test "$($HASH_TOOL "$ARCHIVE" | awk '{print $1}')" = "$EXPECTED_HASH"
if [ ! -f "$BUILD_DIR/ffmpeg-7.0.3/configure" ]; then tar -xf "$ARCHIVE" -C "$BUILD_DIR"; fi
mkdir -p "$BUILD_DIR/objects"
cd "$BUILD_DIR/objects"
CONFIGURE_ARGS=(
    "--prefix=$BUILD_DIR/install"
    --enable-cross-compile --target-os=android --arch=aarch64 --cpu=armv8-a
    "--cc=$CC" "--cxx=$TOOLCHAIN/aarch64-linux-android28-clang++"
    --host-cc=/usr/bin/cc "--ar=$TOOLCHAIN/llvm-ar"
    "--ranlib=$TOOLCHAIN/llvm-ranlib" "--nm=$TOOLCHAIN/llvm-nm" "--strip=$TOOLCHAIN/llvm-strip"
    --enable-static --disable-shared --enable-pic --disable-programs --disable-doc
    --disable-debug --disable-network --disable-autodetect --disable-everything
    --disable-avdevice --disable-postproc --enable-avcodec --enable-avformat
    --enable-avutil --enable-avfilter --enable-swscale --enable-swresample
    --enable-mediacodec --enable-jni
    --enable-decoder=h264,hevc,vp8,vp9,aac,mp3,h264_mediacodec,vp9_mediacodec
    --enable-demuxer=mov,matroska --enable-parser=h264,hevc,aac,mpegaudio,vp9
    --enable-protocol=file,pipe --enable-bsf=h264_mp4toannexb --enable-filter=yadif
)
"$BUILD_DIR/ffmpeg-7.0.3/configure" "${CONFIGURE_ARGS[@]}"
for feature in H264_MEDIACODEC_DECODER VP9_MEDIACODEC_DECODER; do
    grep -q "^#define CONFIG_${feature} 1$" config_components.h
done
! grep -q '^#define CONFIG_VP8_MEDIACODEC_DECODER 1$' config_components.h
make -j"${NXEMU_BUILD_JOBS:-2}"
make install
# Replace all six archives together; retain the shared headers and other platforms.
for library in avcodec avformat avfilter avutil swscale swresample; do
    test -s "$BUILD_DIR/install/lib/lib$library.a"
done
cp "$BUILD_DIR/install/lib/"*.a "$OUTPUT_DIR/"
cp "$BUILD_DIR/ffmpeg-7.0.3/COPYING.LGPLv2.1" "$OUTPUT_DIR/"
