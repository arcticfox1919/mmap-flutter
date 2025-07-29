# mmap2 Native Library Builder

Cross-platform native library builder for mmap2 Flutter plugin using Dart.

## Quick Start

```bash
dart run build.dart --help

# Build for current platform
dart build.dart

# Build for specific platform
# windows
dart run build.dart --platform windows
# macos
dart run build.dart --platform macos --clean
# android
dart run build.dart --platform android --clean --install
# ios 
dart run build.dart --platform ios --version 0.1.0 --clean --install

# Build all platforms supported on current OS
dart build.dart --all

# Custom version
dart build.dart --platform android  --version 0.2.0

# Clean build
dart build.dart --clean --all
```

## Prerequisites

- **Dart SDK** (included with Flutter)
- **CMake 3.18+**
- Platform-specific tools:
  - **Android**: Android NDK (set `ANDROID_NDK_ROOT`)
  - **iOS/macOS**: Xcode + Command Line Tools
  - **Windows**: Visual Studio 2019+ with C++
  - **Linux**: GCC/Clang + build-essential

## Commands

### Basic Usage
```bash
dart build.dart [options] [platform]
```

### Options
- `--version <version>` - Set library version (default: 1.0.0)
- `--platform <platform>` - Build specific platform
- `--all` - Build all supported platforms for current OS
- `--clean` - Clean build directories before building
- `--debug` - Build in Debug mode (default: Release)
- `--release` - Build in Release mode
- `--help`, `-h` - Show help

### Platforms
- `android` - Build Android libraries (all ABIs: arm64-v8a, armeabi-v7a, x86_64)
- `ios` - Build iOS XCFramework (device + simulator)
- `macos` - Build macOS universal dynamic library (Intel + Apple Silicon)
- `windows` - Build Windows x64 dynamic library
- `linux` - Build Linux x86_64 dynamic library

## Output Structure

### Desktop Platforms
Generated as ZIP packages for easy distribution:
```
mmap2-0.1.0-macos-universal.zip
mmap2-0.1.0-windows-x64.zip
mmap2-0.1.0-linux-x86_64.zip
```

Each ZIP contains:
- Dynamic library (`libmmap2.dylib`, `mmap2.dll`, `libmmap2.so`)
- Header file (`mio_wrapper.h`)
- Windows: Import library (`.lib`) and debug symbols (`.pdb`)

### Mobile Platforms
Traditional directory structure:
```
dist/
├── android/
│   ├── arm64-v8a/libmmap2.so
│   ├── armeabi-v7a/libmmap2.so
│   └── x86_64/libmmap2.so
└── ios/
    └── mmap2.xcframework/
```

## Environment Setup

### Android
```bash
export ANDROID_NDK_ROOT=/path/to/android-ndk
export NINJA_PATH=path/to/ninja
```

### iOS/macOS
```bash
xcode-select --install
```

### Windows
- Install Visual Studio 2019+ with "Desktop development with C++" workload
- Ensure CMake is in PATH

### Linux
```bash
sudo apt-get update
sudo apt-get install build-essential cmake
```

## Troubleshooting

### Common Issues

**CMake not found**
```bash
# Install CMake and ensure it's in PATH
cmake --version
```

**Android NDK not found**
```bash
export ANDROID_NDK_ROOT=/path/to/ndk
echo $ANDROID_NDK_ROOT
```

**iOS build fails on non-macOS**
```
Error: iOS builds can only be performed on macOS
```

**Windows build fails**
```
# Use Visual Studio Developer Command Prompt
# Or install Visual Studio with C++ workload
```

### Debug Mode
```bash
dart build.dart --debug --platform android
```

### Verbose Output
The Dart script provides detailed output including:
- Configuration summary
- Per-platform build progress
- Error messages with context
- Final output locations

## Advanced Usage

### Cross-compilation
The build system automatically handles cross-compilation:
- **Android**: Uses NDK toolchain for all ABIs
- **iOS**: Uses ios-cmake toolchain for device + simulator, creates XCFramework supporting:
  - iOS device (arm64)
  - iOS simulator (arm64 + x86_64)
- **macOS**: Builds universal binaries (Intel + Apple Silicon)

### Version Management
Version is passed to CMake as `PROJECT_VERSION` and used in:
- Library versioning
- Package naming
- Framework Info.plist
