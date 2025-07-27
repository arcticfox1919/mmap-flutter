# Native Library Packaging Guide

This document explains how to build and package native libraries for each platform in the mmap2_flutter plugin.

## 🚀 Quick Start (Recommended)

For most users, use the integrated library management tool:

```bash
# 1. Setup guide
dart run mmap2_flutter:setup

# 2. Check status
dart run mmap2_flutter:check

# 3. Install for development
dart run mmap2_flutter:install

# 4. Bundle for distribution
dart run mmap2_flutter:bundle
```

## Overview

The mmap2_flutter plugin requires native libraries to be built and packaged correctly for each target platform:

- **Android**: Dynamic libraries (`.so`) in `android/src/main/jniLibs/`
- **iOS**: Static library (`.a`) referenced in `ios/mmap2_flutter.podspec`
- **Desktop**: Dynamic libraries managed by the included tool

## Directory Structure

```
mmap2_flutter/
├── android/src/main/jniLibs/          # Android dynamic libraries
│   ├── arm64-v8a/libmio_wrapper.so
│   ├── armeabi-v7a/libmio_wrapper.so
│   └── x86_64/libmio_wrapper.so
├── ios/Libraries/                     # iOS static libraries and headers
│   ├── libmio_wrapper.a
│   └── include/mio_wrapper.h
└── native/                            # Desktop build outputs (not packaged)
    ├── windows/mio_wrapper.dll
    ├── linux/libmio_wrapper.so
    └── macos/libmio_wrapper.dylib
```

## Building Native Libraries

### Prerequisites

1. **CMake**: Install CMake 3.16 or later
2. **Platform-specific tools**:
   - Android: Android NDK
   - iOS: Xcode with iOS SDK
   - Windows: Visual Studio 2019/2022
   - Linux: GCC or Clang
   - macOS: Xcode command line tools

### Build Script

Use the provided build script:

```bash
# Build for specific platform
dart run scripts/build_native.dart android
dart run scripts/build_native.dart ios
dart run scripts/build_native.dart windows
dart run scripts/build_native.dart linux
dart run scripts/build_native.dart macos

# Build for all supported platforms (platform-dependent)
dart run scripts/build_native.dart all
```

### Library Management Tool

After building, use the management tool:

```bash
# Install for development
dart run mmap2_flutter:install

# Check installation status  
dart run mmap2_flutter:check

# Bundle for distribution
dart run mmap2_flutter:bundle
```

### Manual Building

#### Android

```bash
# Set up environment
export ANDROID_NDK=/path/to/android-ndk

# Build for arm64-v8a
cmake -B build/android/arm64-v8a \
      -S ../deps/mio_wrapper \
      -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-21 \
      -DCMAKE_BUILD_TYPE=Release

cmake --build build/android/arm64-v8a

# Copy to jniLibs
cp build/android/arm64-v8a/libmio_wrapper.so android/src/main/jniLibs/arm64-v8a/

# Repeat for other architectures (armeabi-v7a, x86_64)
```

#### iOS

```bash
# Configure for iOS universal build
cmake -B build/ios \
      -S ../deps/mio_wrapper \
      -G Xcode \
      -DCMAKE_TOOLCHAIN_FILE=../deps/mio_wrapper/cmake/ios.toolchain.cmake \
      -DPLATFORM=OS64COMBINED \
      -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build/ios --config Release

# Copy static library and headers
cp build/ios/Release/libmio_wrapper.a ios/Libraries/
cp ../deps/mio_wrapper/include/mio_wrapper.h ios/Libraries/include/
```

#### Windows

```bash
# Configure with Visual Studio
cmake -B build/windows \
      -S ../deps/mio_wrapper \
      -G "Visual Studio 17 2022" \
      -A x64 \
      -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build/windows --config Release

# Copy DLL
cp build/windows/Release/mio_wrapper.dll native/windows/
```

#### Linux

```bash
# Configure
cmake -B build/linux \
      -S ../deps/mio_wrapper \
      -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build/linux

# Copy shared library
cp build/linux/libmio_wrapper.so native/linux/
```

#### macOS

```bash
# Configure for universal binary (Intel + Apple Silicon)
cmake -B build/macos \
      -S ../deps/mio_wrapper \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"

# Build
cmake --build build/macos

# Copy dylib
cp build/macos/libmio_wrapper.dylib native/macos/
```

## Platform-Specific Notes

### Android

- Libraries are automatically packaged into the APK when placed in `jniLibs/`
- Support multiple architectures for better device compatibility
- The plugin loads the library using `DynamicLibrary.open('libmio_wrapper.so')`

### iOS

- Uses static linking via CocoaPods specification
- The static library is linked into the final app binary
- No dynamic loading required - uses `DynamicLibrary.process()`
- Headers must be available for CocoaPods integration

### Desktop (Windows/Linux/macOS)

- Libraries must be distributed with the application or installed on the target system
- **Windows**: Place `mio_wrapper.dll` next to the `.exe` file or in PATH
- **Linux**: Place `libmio_wrapper.so` next to the executable or install to system paths
- **macOS**: Place `libmio_wrapper.dylib` next to the app or use proper install paths
- The plugin attempts to load from several standard locations
- **NOT packaged as Flutter assets** - requires separate distribution strategy

## Packaging for Distribution

### For Development

Keep `dependency_overrides` in `pubspec.yaml` for local development:

```yaml
dependency_overrides:
  mmap2:
    path: ../mmap2
```

### For Publishing

1. Remove `dependency_overrides` from `pubspec.yaml`
2. Ensure Android and iOS libraries are built and in correct locations
3. **For Desktop**: Document library distribution requirements for end users
4. Test on target platforms to verify library loading
5. Publish to pub.dev

### Desktop Distribution Strategies

For desktop applications using this plugin:

1. **Bundle with Application**:
   - Copy the dynamic library to the same directory as your executable
   - Include in your installer/package

2. **System Installation**:
   - Install libraries to standard system paths
   - Provide installation scripts for end users

3. **Environment Variables**:
   - Use PATH (Windows), LD_LIBRARY_PATH (Linux), or DYLD_LIBRARY_PATH (macOS)
   - Document this requirement for end users

### CI/CD Considerations

For automated builds:

1. Set up cross-compilation environments
2. Build native libraries for all target platforms
3. Package libraries in the correct directory structure
4. Run tests on target platforms to verify functionality

## Troubleshooting

### Library Not Found

- Verify library is in the correct directory for the platform
- Check file permissions (libraries must be executable)
- Use `dart run build_runner` to regenerate FFI bindings if needed

### Architecture Mismatch

- Ensure Android libraries are built for the correct ABI
- For iOS, verify universal binary includes required architectures
- Check that desktop libraries match the target architecture

### Linking Errors

- Verify all dependencies are available on the target system
- Check that headers match the compiled library version
- Ensure consistent compiler flags across builds

## Example Integration

```dart
import 'package:mmap2_flutter/mmap2_flutter.dart';
import 'package:mmap2/mmap2.dart';

void main() async {
  // Initialize the native library
  await MmapFlutter.initialize();
  
  // Use the mmap API
  final mmap = Mmap.fromFile('path/to/file');
  // ... use mmap
  mmap.close();
}
```

This setup ensures that native libraries are properly packaged and loaded across all supported Flutter platforms.
