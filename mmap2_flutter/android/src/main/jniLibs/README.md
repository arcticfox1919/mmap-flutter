# Android JNI Libraries

## Overview

This directory contains native shared libraries (`.so` files) for different Android architectures. The libraries are automatically packaged into the APK when building the Flutter application.

## Supported Architectures

- **arm64-v8a**: 64-bit ARM (most modern Android devices)
- **armeabi-v7a**: 32-bit ARM (older Android devices)
- **x86_64**: 64-bit x86 (Android emulators, some tablets)

## Building Libraries

### Using Android NDK

```bash
# Set NDK path
export ANDROID_NDK=/path/to/android-ndk

# Build for arm64-v8a
cmake -B build/android/arm64-v8a \
      -S ../../../deps/mio_wrapper \
      -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
      -DANDROID_ABI=arm64-v8a \
      -DANDROID_PLATFORM=android-21 \
      -DCMAKE_BUILD_TYPE=Release

cmake --build build/android/arm64-v8a

# Copy to jniLibs
cp build/android/arm64-v8a/libmio_wrapper.so arm64-v8a/
```

Repeat for other architectures by changing `ANDROID_ABI`.

### File Placement

Place the compiled libraries in the correct subdirectories:

```
android/src/main/jniLibs/
├── arm64-v8a/
│   └── libmio_wrapper.so
├── armeabi-v7a/
│   └── libmio_wrapper.so
└── x86_64/
    └── libmio_wrapper.so
```

## Library Loading

The Flutter plugin loads the library using:

```dart
DynamicLibrary.open('libmio_wrapper.so')
```

Android automatically selects the correct architecture-specific library based on the device.

## Verification

To verify your libraries:

```bash
# Check architecture
file arm64-v8a/libmio_wrapper.so
# Should show: ELF 64-bit LSB shared object, ARM aarch64

# Check symbols
nm -D arm64-v8a/libmio_wrapper.so | grep mio_
# Should show exported mio_* functions
```

## Troubleshooting

- **Library not found**: Ensure the `.so` file is in the correct architecture directory
- **Wrong architecture**: Verify you're building for the correct `ANDROID_ABI`
- **Missing symbols**: Check that all required functions are exported from the library
- **Runtime errors**: Use `adb logcat` to check for loading errors

## Notes

- Minimum Android API level: 21 (Android 5.0)
- Libraries are automatically stripped of debug symbols in release builds
- The Gradle build system handles packaging into the APK
