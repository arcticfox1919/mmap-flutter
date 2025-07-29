import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:mmap2/mmap2.dart';
import 'package:mmap2_flutter/src/library_loader.dart';

/// Flutter-specific initialization helper for Mmap
class MmapFlutter {
  static bool _initialized = false;

  /// Initialize Mmap for Flutter applications
  ///
  /// This method handles platform-specific initialization for Flutter apps,
  /// including loading native libraries from the correct locations.
  static void initialize() {
    if (_initialized) return;

    ffi.DynamicLibrary library;
    if (Platform.isAndroid) {
      // On Android, the library should be packaged with the app in jniLibs
      library = LibraryLoader.loadAndroidLibrary();
    } else if (Platform.isIOS) {
      // On iOS, the library is statically linked into the app
      library = ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      // On Windows, load from plugin's native directory
      library = LibraryLoader.loadWindowsLibrary();
    } else if (Platform.isMacOS) {
      // On macOS, load from plugin's native directory
      library = LibraryLoader.loadMacOSLibrary();
    } else if (Platform.isLinux) {
      // On Linux, load from plugin's native directory
      library = LibraryLoader.loadLinuxLibrary();
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }

    Mmap.initialize(library);
    _initialized = true;
  }

  /// Check if the library is initialized
  static bool get isInitialized => _initialized;

  /// Reset initialization state (mainly for testing)
  static void reset() {
    _initialized = false;
  }
}
