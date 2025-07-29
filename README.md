# Mmap Flutter

A Flutter package providing memory-mapped file I/O functionality using the [mio](https://github.com/mandreyel/mio) C++ library.

[Mmap2](https://pub.dev/packages/mmap2) provides efficient memory-mapped file access for Dart applications, allowing you to work with large files without loading them entirely into memory. This package wraps the powerful mio C++ library and exposes a clean, type-safe Dart API.

## Project Structure

```
mmap-flutter/
├── deps/                    # Native dependencies
│   ├── mio/                # Original mio C++ library (submodule)
│   └── mio_wrapper/        # C wrapper for mio library
│       ├── include/        # Header files
│       ├── src/           # Source files
│       └── CMakeLists.txt # Build configuration
├── mmap2/                  # Core Dart package (FFI bindings)
│   ├── lib/               # Dart library code
│   ├── example/           # Usage examples
│   ├── test/              # Unit tests
│   └── ffigen.yaml        # FFI binding generation config
├── mmap2_flutter/          # Flutter plugin package
│   ├── lib/               # Flutter-specific code
│   ├── example/           # Flutter example app
│   ├── android/           # Android platform code
│   ├── ios/               # iOS platform code
│   └── [linux|macos|windows]/ # Desktop platform code
```

## Package Architecture

### mmap2 (Core Package)
- Pure Dart package with FFI bindings
- Can be used in any Dart project (CLI, server, etc.)
- Provides core memory mapping functionality
- Manual library loading and initialization

### mmap2_flutter (Flutter Plugin)
- Flutter-specific wrapper around mmap2
- Handles platform-specific library loading
- Includes native library binaries for android and ios
- Provides simplified initialization for Flutter apps

## Building

### Prerequisites

- CMake 3.18 or later
- C++14 compatible compiler
- Dart SDK
- Flutter SDK (for Flutter projects)

### Build Steps

1. **Clone the repository with submodules:**

   ```bash
   git clone --recursive https://github.com/your-username/mmap-flutter.git
   cd mmap-flutter
   ```

2. **Setting Environment Variables**

   ```shell
   export ANDROID_NDK_ROOT=path
   export NINJA_PATH=path/ninja
   
   # windows
   set ANDROID_NDK_ROOT=path
   set NINJA_PATH=path/ninja
   ```

3. **Build the native library:**

   ```shell
   cd mmap-flutter/deps/mio_wrapper
   # help
   dart run build.dart --help
   # windows
   dart run build.dart --platform windows
   # macos
   dart run build.dart --platform macos --clean
   # android
   dart run build.dart --platform android --clean --install
   # ios 
   dart run build.dart --platform ios --version 0.1.0 --clean --install
   ```

4. **Run tests:**

   Open `mmap2\test\mmap2_test.dart`,set the current dynamic library path

   ```dart
   setUpAll(() async {
       // Initialize the library
       try {
         Mmap.setLibraryLoader(() {
           // set the current dynamic library path
           return ffi.DynamicLibrary.open('libmmap2 path');
         });
         Mmap.initializePlatform();
       } catch (e) {
         print('Warning: Could not load mmap library: $e');
         print(
           'Tests will be skipped. Make sure to build the native library first.',
         );
       }
     });
   ```

   Run `dart test`

For detailed build information, see the document [mmap2 Native Library Builder](deps/mio_wrapper/README.md)

## Usage

### Initialization

The library supports three initialization methods depending on your use case:

#### 1. Flutter Applications with MmapFlutter (Recommended)
For Flutter projects, you can additionally add `mmap2_flutter` dependency which provides pre-built native libraries for Android and iOS platforms, along with unified initialization for Flutter apps:

**Step 1: Add dependencies to `pubspec.yaml`**
```yaml
dependencies:
  flutter:
    sdk: flutter
  mmap2_flutter: ^0.2.1    # Flutter plugin package
  mmap2: ^0.2.1            # Core package 
```

**Step 2: Initialize and use**
```dart
import 'package:mmap2_flutter/mmap2_flutter.dart';
import 'package:mmap2/mmap2.dart';

void main() async {
  // Automatic cross-platform initialization for Flutter
  MmapFlutter.initialize();
  
  // Now you can use Mmap
  final mmap = Mmap.fromFile('example.txt');
  // ...
}
```

#### 2. Pure Dart Applications with Automatic Platform Detection
For pure Dart applications (CLI, server, etc.), use automatic platform detection:

**Step 1: Add dependency to `pubspec.yaml`**
```yaml
dependencies:
  mmap2: ^0.2.1    # Core package only
```

**Step 2: Initialize and use**
```dart
import 'package:mmap2/mmap2.dart';

void main() async {
  // Automatic platform detection - loads the appropriate library
  // Windows: mmap2.dll, Linux: libmmap2.so, macOS: libmmap2.dylib
  Mmap.initializePlatform();
  
  // Now you can use Mmap
  final mmap = Mmap.fromFile('example.txt');
  // ...
}
```

#### 3. Custom Library Loading
For advanced use cases where you need custom library loading logic:

**Step 1: Add dependency to `pubspec.yaml`**
```yaml
dependencies:
  mmap2: ^0.2.1      # Core package only
```

**Step 2: Set custom loader and initialize**
```dart
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:mmap2/mmap2.dart';

void main() async {
  // Set custom library loader function
  Mmap.setLibraryLoader(() {
    // Your custom library loading logic
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('path/to/custom/mmap2.dll');
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('path/to/custom/libmmap2.so');
    }
    // ... other platforms
    throw UnsupportedError('Unsupported platform');
  });
  
  // Initialize with custom loader
  Mmap.initializePlatform();
  
  // Or clear custom loader to revert to default
  // Mmap.clearLibraryLoader();
  
  // Now you can use Mmap
  final mmap = Mmap.fromFile('example.txt');
  // ...
}
```

### Basic Example

```dart
import 'dart:io';
import 'package:mmap2/mmap2.dart';

void main() async {
  // Initialize the library (choose one of the methods above)
  Mmap.initializePlatform();  // Method 2: Automatic platform detection
  
  // Create a test file
  final file = File('example.txt');
  await file.writeAsString('Hello, Memory Mapped World!');
  
  // Read-only memory mapping
  final readMmap = Mmap.fromFile(file.path, mode: AccessMode.read);
  final data = readMmap.data;
  final content = String.fromCharCodes(data);
  print('Content: $content');
  readMmap.close();
  
  // Write-enabled memory mapping
  final writeMmap = Mmap.fromFile(file.path, mode: AccessMode.write);
  final writableData = writeMmap.writableData;
  
  // Modify the content
  writableData[0] = 'h'.codeUnitAt(0); // Change 'H' to 'h'
  
  // Sync changes to disk
  writeMmap.sync();
  writeMmap.close();
  
  // Clean up
  // await file.delete();
}
```

### API Reference

#### Initialization Methods

```dart
// Method 1: Flutter applications (automatic platform handling)
MmapFlutter.initialize();

// Method 2: Pure Dart applications (automatic platform detection)
Mmap.initializePlatform();

// Method 3: Custom library loading
Mmap.setLibraryLoader(() => ffi.DynamicLibrary.open('custom/path'));
Mmap.initializePlatform();

// Clear custom loader (revert to default)
Mmap.clearLibraryLoader();
```

#### Creating Memory Maps
```dart
// From file path
final mmap = Mmap.fromFile('path/to/file.txt', 
    mode: AccessMode.read,  // or AccessMode.write
    offset: 0,              // optional offset
    length: 1024            // optional length (null = entire file)
);

// From file handle
final mmap = Mmap.fromHandle(fileHandle, 
    mode: AccessMode.write,
    offset: 0,
    length: 1024
);
```

#### Accessing Data
```dart
// Read-only access (works for both read and write maps)
final data = mmap.data;  // Uint8List

// Write access (only for write-enabled maps)
final writableData = mmap.writableData;  // Uint8List
writableData[0] = 65;  // Modify data directly
```

#### Properties and Methods
```dart
print('Size: ${mmap.size}');                    // Logical size
print('Mapped length: ${mmap.mappedLength}');   // Actual mapped size
print('Is open: ${mmap.isOpen}');               // Check if open
print('Is mapped: ${mmap.isMapped}');           // Check if mapped
print('Access mode: ${mmap.accessMode}');       // Get access mode

mmap.sync();   // Sync changes to disk (write maps only)
mmap.close();  // Close and free resources
```

### Error Handling

The library provides specific exception types:

```dart
try {
  final mmap = Mmap.fromFile('nonexistent.txt');
} on FileNotFoundException catch (e) {
  print('File not found: $e');
} on PermissionDeniedException catch (e) {
  print('Permission denied: $e');
} on MmapException catch (e) {
  print('General mmap error: $e');
}
```

## Platform Support

| Platform | Library File | Initialization Methods | Notes |
|----------|-------------|----------------------|-------|
| Windows  | `mmap2.dll` | 1. `MmapFlutter.initialize()`<br>2. `Mmap.initializePlatform()`<br>3. `Mmap.setLibraryLoader()` | Requires Visual Studio 2015+ |
| Linux    | `libmmap2.so` | 1. `MmapFlutter.initialize()`<br>2. `Mmap.initializePlatform()`<br>3. `Mmap.setLibraryLoader()` | Requires GCC 4.8+ or Clang 3.4+ |
| macOS    | `libmmap2.dylib` | 1. `MmapFlutter.initialize()`<br>2. `Mmap.initializePlatform()`<br>3. `Mmap.setLibraryLoader()` | Requires Xcode 8.0+ |
| Android  | `libmmap2.so` | 1. `MmapFlutter.initialize()` (recommended)<br>2. Custom loading via `setLibraryLoader()` | Packaged with APK |
| iOS      | Static linking | 1. `MmapFlutter.initialize()` (recommended)<br>2. `DynamicLibrary.process()` | Statically linked into app |

### Cross-Platform Considerations

- **Android**: Native library is packaged in the APK's `jniLibs` directory
- **iOS**: Library is statically linked into the application binary
- **Desktop**: Dynamic library loading with automatic path resolution
- **Mobile**: May have additional sandbox restrictions on file access

For detailed build instructions for each platform, see [Cross-Platform Build Guide](docs/CROSS_PLATFORM_BUILD.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The original mio library is also licensed under the MIT License.
