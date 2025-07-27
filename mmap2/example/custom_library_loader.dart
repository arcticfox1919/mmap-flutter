import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:mmap2/mmap2.dart';

void main() {
  // Example 1: Using custom library loader with specific path
  print('Example 1: Custom library loader with specific path');

  Mmap.setLibraryLoader(() {
    // Custom logic to determine library path
    final libPath = _getCustomLibraryPath();
    print('Loading library from: $libPath');
    return ffi.DynamicLibrary.open(libPath);
  });

  // Initialize with custom loader
  Mmap.initializePlatform();

  print('✅ Initialized with custom library loader\n');

  // Example 2: Using default platform detection (no custom loader)
  print('Example 3: Default platform detection');

  // Clear custom loader to use default
  Mmap.clearLibraryLoader();

  // This will use the default loadLibrary() method
  Mmap.initializePlatform();

  print('✅ Initialized with default platform detection');
}

String _getCustomLibraryPath() {
  // Example: Load from a specific directory based on environment
  final customDir = Platform.environment['MMAP_LIB_DIR'];
  if (customDir != null) {
    if (Platform.isWindows) {
      return '$customDir\\mmap2.dll';
    } else {
      return '$customDir/libmmap2.so';
    }
  }

  // Fallback to current directory
  if (Platform.isWindows) {
    return '.\\mmap2.dll';
  } else {
    return './libmmap2.so';
  }
}
