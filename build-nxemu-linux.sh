#!/bin/bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
prefix="$root/linux-x64"
build="$root/linux-build"
mkdir -p "$build"
cd "$build"
"$root/configure" \
  --prefix="$prefix" \
  --disable-shared \
  --enable-static \
  --disable-programs \
  --disable-doc \
  --disable-debug \
  --disable-autodetect \
  --disable-network \
  --disable-avdevice \
  --disable-everything \
  --enable-avcodec \
  --enable-avfilter \
  --enable-swscale \
  --enable-swresample \
  --enable-decoder=h264,hevc,vp8,vp9 \
  --enable-parser=h264,hevc,vp8,vp9 \
  --enable-filter=yadif,scale,format \
  --enable-protocol=file \
  --extra-cflags="-fPIC" \
  --enable-pic
make -j"$(nproc)"
make install
