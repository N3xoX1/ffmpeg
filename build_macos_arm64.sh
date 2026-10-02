#!/usr/bin/env bash
set -euo pipefail

FFMPEG_VERSION="7.0.3"
FFMPEG_COMMIT="eaddd1d7140bab19e5a4403d3c0f61fe5f59cb75"
DEPLOYMENT_TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/lib/macos-arm64"
JOBS="${JOBS:-$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)}"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
    echo "error: build_macos_arm64.sh must run natively on Apple Silicon macOS" >&2
    exit 1
fi

for tool in git make xcrun; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "error: required tool not found: $tool" >&2
        exit 1
    fi
done

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/nxemu-ffmpeg-${FFMPEG_VERSION}.XXXXXX")"
cleanup() {
    if [[ "${KEEP_BUILD:-0}" == "1" ]]; then
        echo "Keeping FFmpeg build directory: $WORK_DIR"
    else
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

SOURCE_DIR="$WORK_DIR/source"
SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"
SDK_VERSION="$(xcrun --sdk macosx --show-sdk-version)"
CC="$(xcrun --sdk macosx -f clang)"
AR="$(xcrun --sdk macosx -f ar)"
RANLIB="$(xcrun --sdk macosx -f ranlib)"
STRIP="$(xcrun --sdk macosx -f strip)"

# Fetch the exact FFmpeg 7.0.3 release commit rather than a moving branch.
git init -q "$SOURCE_DIR"
git -C "$SOURCE_DIR" remote add origin https://github.com/FFmpeg/FFmpeg.git
git -C "$SOURCE_DIR" fetch -q --depth 1 origin "$FFMPEG_COMMIT"
git -C "$SOURCE_DIR" checkout -q --detach FETCH_HEAD

ACTUAL_COMMIT="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
if [[ "$ACTUAL_COMMIT" != "$FFMPEG_COMMIT" ]]; then
    echo "error: expected FFmpeg commit $FFMPEG_COMMIT, got $ACTUAL_COMMIT" >&2
    exit 1
fi

COMMON_FLAGS="-arch arm64 -isysroot $SDKROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
CONFIGURE_FLAGS="static,no-shared,pic,disable-everything,no-avdevice,no-avformat,no-swresample,no-programs,no-network,no-autodetect,decoders:h264/hevc/vp8/vp9,filter:yadif,builtin-filters:buffer/buffersink,videotoolbox,hwaccels:h264/hevc/vp9_videotoolbox"

# Avoid accidental linkage against Homebrew/MacPorts libraries. Everything NXEmu
# needs here is implemented inside FFmpeg or the macOS SDK.
export PKG_CONFIG_PATH=""
export PKG_CONFIG_LIBDIR="$WORK_DIR/no-pkg-config"
mkdir -p "$PKG_CONFIG_LIBDIR"

pushd "$SOURCE_DIR" >/dev/null
./configure \
    --arch=arm64 \
    --target-os=darwin \
    --cc="$CC" \
    --host-cc="$CC" \
    --host-ld="$CC" \
    --ar="$AR" \
    --ranlib="$RANLIB" \
    --strip="$STRIP" \
    --enable-static \
    --disable-shared \
    --enable-pic \
    --disable-programs \
    --disable-doc \
    --disable-debug \
    --disable-network \
    --disable-autodetect \
    --disable-everything \
    --disable-avdevice \
    --disable-avformat \
    --disable-swresample \
    --enable-avcodec \
    --enable-avfilter \
    --enable-avutil \
    --enable-swscale \
    --enable-pthreads \
    --enable-videotoolbox \
    --enable-hwaccel=h264_videotoolbox \
    --enable-hwaccel=hevc_videotoolbox \
    --enable-hwaccel=vp9_videotoolbox \
    --enable-decoder=h264 \
    --enable-decoder=hevc \
    --enable-decoder=vp8 \
    --enable-decoder=vp9 \
    --enable-filter=yadif \
    --host-cflags="$COMMON_FLAGS" \
    --host-ldflags="$COMMON_FLAGS" \
    --extra-cflags="$COMMON_FLAGS" \
    --extra-ldflags="$COMMON_FLAGS"

for component in VIDEOTOOLBOX H264_VIDEOTOOLBOX_HWACCEL HEVC_VIDEOTOOLBOX_HWACCEL VP9_VIDEOTOOLBOX_HWACCEL; do
    if ! grep -q "^#define CONFIG_${component} 1$" config.h config_components.h; then
        echo "error: FFmpeg configured without ${component}" >&2
        exit 1
    fi
done

make -j"$JOBS"
popd >/dev/null

mkdir -p "$OUTPUT_DIR"
rm -f \
    "$OUTPUT_DIR/libavcodec.a" \
    "$OUTPUT_DIR/libavfilter.a" \
    "$OUTPUT_DIR/libavutil.a" \
    "$OUTPUT_DIR/libswscale.a" \
    "$OUTPUT_DIR/BUILDINFO.txt"

cp "$SOURCE_DIR/libavcodec/libavcodec.a" "$OUTPUT_DIR/libavcodec.a"
cp "$SOURCE_DIR/libavfilter/libavfilter.a" "$OUTPUT_DIR/libavfilter.a"
cp "$SOURCE_DIR/libavutil/libavutil.a" "$OUTPUT_DIR/libavutil.a"
cp "$SOURCE_DIR/libswscale/libswscale.a" "$OUTPUT_DIR/libswscale.a"

for archive in libavcodec.a libavfilter.a libavutil.a libswscale.a; do
    archs="$(xcrun lipo -archs "$OUTPUT_DIR/$archive")"
    if [[ "$archs" != "arm64" ]]; then
        echo "error: $archive is not arm64-only (archs=$archs)" >&2
        exit 1
    fi
done

cat > "$OUTPUT_DIR/BUILDINFO.txt" <<INFO
version=$FFMPEG_VERSION
commit=$FFMPEG_COMMIT
platform=macos-arm64
sdk_version=$SDK_VERSION
deployment_target=$DEPLOYMENT_TARGET
configure_flags=$CONFIGURE_FLAGS
libraries=libavcodec.a,libavfilter.a,libavutil.a,libswscale.a
decoders=h264,hevc,vp8,vp9
filters=buffer,buffersink,yadif
hwaccels=h264_videotoolbox,hevc_videotoolbox,vp9_videotoolbox
frameworks=CoreFoundation,CoreMedia,CoreVideo,VideoToolbox
filter_selection=yadif;buffer_and_buffersink_are_builtin
shared=disabled
autodetect=disabled
INFO

printf 'Built pinned FFmpeg %s for macOS arm64 in %s\n' "$FFMPEG_VERSION" "$OUTPUT_DIR"
printf 'Commit: %s\n' "$FFMPEG_COMMIT"
printf 'Deployment target: macOS %s\n' "$DEPLOYMENT_TARGET"
