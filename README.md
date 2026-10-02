# FFmpeg Static Libraries for Windows

Pre-built FFmpeg 7.0.3 static libraries compiled with MSVC `/MT` runtime.

Slim build for nxemu Host1x / NVDEC: H.264, HEVC, VP8, VP9 decode, yadif,
swscale, D3D11VA/DXVA2. No debug symbols (`--disable-debug`). Rebuild from
`D:\Dev\ffmpeg-7.0.3` with `build_msvc_mt.bat`.

## Contents
- **libavcodec.lib** - Encoding/decoding
- **libavfilter.lib** - Filters (yadif deinterlace)
- **libavutil.lib** - Utilities
- **libswscale.lib** - Scaling/conversion (VIC)

`libavformat.lib`, `libavdevice.lib`, and `libswresample.lib` are also
installed so existing Visual Studio link lines keep working.

## Configuration
- FFmpeg version: 7.0.3
- Compiler: MSVC (Visual Studio 2022)
- Runtime: `/MT` (static)
- Platform: x64
- Debug symbols: disabled

## Usage in Visual Studio
1. Add to Additional Include Directories: `$(SolutionDir)external\ffmpeg\include`
2. Add to Additional Library Directories: `$(SolutionDir)external\ffmpeg\lib`
3. Add to Additional Dependencies: `libavcodec.lib libavfilter.lib libavutil.lib libswscale.lib`
4. Set Runtime Library to `/MT`

## macOS Apple Silicon

On an Apple Silicon Mac, rebuild the archives with:

```sh
./build_macos_arm64.sh
```

The script writes these files to `lib/macos-arm64/`:

- `libavcodec.a`
- `libavfilter.a`
- `libavutil.a`
- `libswscale.a`
- `BUILDINFO.txt`

The macOS build is intentionally minimal: static ARM64 libraries with the
H.264, HEVC, VP8 and VP9 decoders, the `yadif` filter, and swscale.
VideoToolbox is enabled explicitly for H.264, HEVC and VP9; unsupported
streams retain software decoding. CMake links the CoreFoundation, CoreMedia,
CoreVideo and VideoToolbox frameworks. The rebuild checks that the requested
hardware accelerators were enabled before installing the archives. Automatic
external-library detection is disabled so a rebuild cannot silently acquire
Homebrew or MacPorts dependencies.

`MACOSX_DEPLOYMENT_TARGET` may be set when rebuilding. It defaults to `11.0`,
the first macOS release supporting Apple Silicon.
