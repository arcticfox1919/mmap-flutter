import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:mmap2/mmap2.dart';

/// Flutter plugin example showing how to use custom library loader
class MmapFlutterPlugin {
  static bool _initialized = false;

  /// Initialize the plugin with custom library loading logic
  static Future<void> initialize() async {
    if (_initialized) return;

    // Set up custom library loader for Flutter plugin context
    Mmap.setLibraryLoader(_loadPluginLibrary);

    try {
      Mmap.initializePlatform();
      _initialized = true;
      print('✅ Mmap Flutter plugin initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Mmap Flutter plugin: $e');
      rethrow;
    }
  }

  /// Custom library loader that handles Flutter plugin library paths
  static ffi.DynamicLibrary _loadPluginLibrary() {
    if (Platform.isAndroid) {
      // For Android, the library is typically bundled with the APK
      return ffi.DynamicLibrary.open('libmmap2.so');
    } else if (Platform.isIOS) {
      // For iOS, the library is statically linked into the app
      return ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      // For Windows desktop, try multiple locations
      final possiblePaths = [
        'mmap2.dll', // Current directory
        'lib/mmap2.dll', // Relative lib directory
        './windows/mmap2.dll', // Flutter Windows build output
        '../native/windows/mmap2.dll', // Development path
      ];

      for (final path in possiblePaths) {
        try {
          return ffi.DynamicLibrary.open(path);
        } catch (e) {
          print('Failed to load from $path: $e');
          continue;
        }
      }

      throw Exception('Could not find mmap2.dll in any expected location');
    } else if (Platform.isMacOS) {
      // For macOS, try framework and dylib locations
      final possiblePaths = [
        'libmmap2.dylib', // Current directory
        './macos/libmmap2.dylib', // Flutter macOS build output
        '../native/macos/libmmap2.dylib', // Development path
        '/usr/local/lib/libmmap2.dylib', // System installation
      ];

      for (final path in possiblePaths) {
        try {
          return ffi.DynamicLibrary.open(path);
        } catch (e) {
          print('Failed to load from $path: $e');
          continue;
        }
      }

      throw Exception('Could not find libmmap2.dylib in any expected location');
    } else if (Platform.isLinux) {
      // For Linux, try common library locations
      final possiblePaths = [
        'libmmap2.so', // Current directory
        './linux/libmmap2.so', // Flutter Linux build output
        '../native/linux/libmmap2.so', // Development path
        '/usr/local/lib/libmmap2.so', // System installation
        '/usr/lib/libmmap2.so', // System library directory
      ];

      for (final path in possiblePaths) {
        try {
          return ffi.DynamicLibrary.open(path);
        } catch (e) {
          print('Failed to load from $path: $e');
          continue;
        }
      }

      throw Exception('Could not find libmmap2.so in any expected location');
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  /// Create a memory map from file path (convenience method)
  static Future<Mmap> openFile(
    String path, {
    AccessMode mode = AccessMode.read,
    int offset = 0,
    int? length,
  }) async {
    await initialize();
    return Mmap.fromFile(path, mode: mode, offset: offset, length: length);
  }
}

// Example usage in a Flutter app
void main() async {
  try {
    // Initialize the plugin
    await MmapFlutterPlugin.initialize();

    // Use the plugin
    final mmap = await MmapFlutterPlugin.openFile(
      '/path/to/your/file.bin',
      mode: AccessMode.read,
    );

    print('File size: ${mmap.size} bytes');
    print('First 10 bytes: ${mmap.data.take(10).toList()}');

    mmap.close();
  } catch (e) {
    print('Error: $e');
  }
}
