# FFmpeg Static Libraries for Windows

Pre-built FFmpeg 7.0 static libraries compiled with MSVC `/MT` runtime.

## Contents
- **libavcodec.lib** - Encoding/decoding
- **libavfilter.lib** - Filters
- **libavutil.lib** - Utilities
- **libswscale.lib** - Scaling/conversion

## Configuration
- FFmpeg version: 7.0
- Compiler: MSVC (Visual Studio 2022)
- Runtime: `/MT` (static)
- Platform: x64

## Usage in Visual Studio
1. Add to Additional Include Directories: `$(SolutionDir)ffmpeg-libs\include`
2. Add to Additional Library Directories: `$(SolutionDir)ffmpeg-libs\lib`
3. Add to Additional Dependencies: `libavcodec.lib libavfilter.lib libavutil.lib libswscale.lib`
4. Set Runtime Library to `/MT`