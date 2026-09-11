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
