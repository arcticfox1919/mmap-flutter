# mmap2 Native Library Builder

Cross-platform native library builder for mmap2 Flutter plugin using Dart.

## Quick Start

```bash
# Build for current platform
dart build.dart

# Build for specific platform
dart build.dart android
dart build.dart ios
dart build.dart macos
dart build.dart windows
dart build.dart linux

# Build all platforms supported on current OS
dart build.dart --all

# Custom version
dart build.dart --version 1.2.0 macos

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
mmap2-1.0.0-macos-universal.zip
mmap2-1.0.0-windows-x64.zip
mmap2-1.0.0-linux-x86_64.zip
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

## Examples

### Build Android Libraries
```bash
dart build.dart android
```
Outputs: `dist/android/{arm64-v8a,armeabi-v7a,x86_64}/libmmap2.so`

### Build iOS XCFramework
```bash
dart build.dart ios
```
Outputs: `dist/ios/mmap2.xcframework`

### Build macOS Universal Library
```bash
dart build.dart macos
```
Outputs: `mmap2-1.0.0-macos-universal.zip`

### Build with Custom Version
```bash
dart build.dart --version 2.1.0 --all
```

### Clean Build
```bash
dart build.dart --clean android ios
```

## Environment Setup

### Android
```bash
export ANDROID_NDK_ROOT=/path/to/android-ndk
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

## Integration with Flutter

The generated libraries are designed to work seamlessly with Flutter projects:

1. **Android**: Copy `.so` files to `android/src/main/jniLibs/{abi}/`
2. **iOS**: Add XCFramework to Xcode project or use CocoaPods
3. **macOS**: Add `.dylib` to macOS bundle
4. **Windows**: Place `.dll` alongside executable
5. **Linux**: Place `.so` in library path

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

### iOS XCFramework Benefits
The iOS build creates an XCFramework instead of traditional Fat libraries for several advantages:
- **Architecture Compatibility**: Supports both arm64 device and arm64 simulator (which Fat libraries cannot handle)
- **Modern Standard**: XCFramework is Apple's recommended distribution format
- **Xcode Integration**: Better integration with modern Xcode versions
- **Multi-platform Support**: Single package supports all iOS targets

### Cross-compilation
The build system automatically handles cross-compilation:
- **Android**: Uses NDK toolchain for all ABIs
- **iOS**: Uses ios-cmake toolchain for device + simulator, creates XCFramework supporting:
  - iOS device (arm64)
  - iOS simulator (arm64 + x86_64)
- **macOS**: Builds universal binaries (Intel + Apple Silicon)

### Custom CMake Flags
Modify the Dart script to add custom CMake flags:
```dart
final result = Process.runSync('cmake', [
  '-B', buildDir.path,
  '-DCUSTOM_FLAG=value',
  // ... other flags
  '.'
]);
```

### Version Management
Version is passed to CMake as `PROJECT_VERSION` and used in:
- Library versioning
- Package naming
- Framework Info.plist

## Contributing

When adding new platforms or features:
1. Update the `_buildPlatform` method
2. Add platform detection logic
3. Update help text and documentation
4. Test on target platform
