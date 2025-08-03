# Mmap2

A high-performance Dart package for memory-mapped file I/O using native FFI bindings to the [mio](https://github.com/mandreyel/mio) C++ library.

## Overview

Mmap2 provides efficient memory-mapped file access for Dart applications, allowing you to work with large files without loading them entirely into memory. This package wraps the powerful mio C++ library and exposes a clean, type-safe Dart API.

### Key Features

- **High Performance**: Direct memory access without copying data between kernel and user space
- **Cross-Platform**: Supports Windows, Linux, macOS, Android, and iOS
- **Memory Efficient**: Map only the portions of files you need
- **Type Safe**: Full Dart type safety with comprehensive error handling
- **Flexible Access**: Both read-only and read-write memory mapping
- **Zero-Copy Operations**: Direct access to mapped memory regions

### Use Cases

- **Large File Processing**: Process large datasets without loading them entirely into memory

- **Database Implementations**: Build efficient file-based storage systems

- **Log File Analysis**: Stream through massive log files

- **Binary Data Manipulation**: Direct access to binary file formats


## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  mmap2: ^0.2.1
```

For Flutter projects, you can additionally add `mmap2_flutter` dependency which provides pre-built native libraries for Android and iOS platforms, along with unified initialization for Flutter apps.

For desktop platforms (Windows, Linux, macOS), you can download pre-built libraries from the [releases page](https://github.com/arcticfox1919/mmap-flutter/releases). These can be installed to your system's library search paths or bundled with your executable in the same directory.

```yaml
dependencies:
  mmap2_flutter: ^0.2.1
  mmap2: ^0.2.1
```

## Quick Start

```dart
import 'dart:io';
import 'package:mmap2/mmap2.dart';

void main() {
  // Initialize the library
  Mmap.initializePlatform();
  
  // Create and map a file
  final file = File('data.txt');
  file.writeAsStringSync('Hello, Memory Mapped World!');
  
  // Read-only mapping
  final mmap = Mmap.fromFile(file.path);
  print('Content: ${String.fromCharCodes(mmap.data)}');
  
  // Clean up
  mmap.close();
  file.deleteSync();
}
```

### Initialization

The library supports three initialization methods depending on your use case:

#### 1. Flutter Applications with MmapFlutter (Recommended)
For Flutter projects, you can additionally add `mmap2_flutter` dependency which provides pre-built native libraries for Android and iOS platforms, along with unified initialization for Flutter apps.

For desktop platforms (Windows, Linux, macOS), you can download pre-built libraries from the [releases page](https://github.com/arcticfox1919/mmap-flutter/releases). These can be installed to your system's library search paths or bundled with your executable in the same directory.

**Step 1: Add dependencies to `pubspec.yaml`**
```yaml
dependencies:
  flutter:
    sdk: flutter
  mmap2_flutter: ^0.2.1    # Flutter plugin package
  mmap2: ^0.2.1           # Core package
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
For pure Dart applications (CLI, server, etc.), use automatic platform detection. Pre-built desktop libraries are available from the [releases page](https://github.com/arcticfox1919/mmap-flutter/releases) and should be installed to your system's library search paths or placed in the same directory as your executable.

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
  mmap2: ^0.2.1    # Core package only
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
import 'package:mmap2/mmap2.dart';

try {
  final mmap = Mmap.fromFile('large-dataset.bin');
  // Process data...
} on FileNotFoundException catch (e) {
  print('File not found: ${e.message}');
} on PermissionDeniedException catch (e) {
  print('Access denied: ${e.message}');
} on OutOfMemoryException catch (e) {
  print('Insufficient memory: ${e.message}');
} on MappingFailedException catch (e) {
  print('Mapping failed: ${e.message}');
} on MmapException catch (e) {
  print('General error: ${e.message}');
}
```

## Package Variants

This package is available in two variants:

### mmap2 (This Package)
- **Target**: Pure Dart applications (CLI, server, desktop)
- **Dependencies**: Only core Dart dependencies
- **Setup**: Manual library loading and initialization
- **Use Case**: Maximum control and flexibility

### mmap2_flutter
- **Target**: Flutter applications (mobile, desktop, web)
- **Dependencies**: Flutter SDK
- **Setup**: Automatic platform-specific library loading
- **Use Case**: Simplified Flutter integration


## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

The underlying mio C++ library is also licensed under the MIT License.