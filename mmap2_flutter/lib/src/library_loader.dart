import 'dart:ffi' as ffi;

class LibraryLoader {
  static ffi.DynamicLibrary loadAndroidLibrary() =>
      ffi.DynamicLibrary.open('libmmap2.so');

  static ffi.DynamicLibrary loadWindowsLibrary() {
    // For Windows desktop, try multiple strategies:
    // 1. Adjacent to executable (most common for distributed apps)
    // 2. In PATH environment variable
    // 3. System directories
    final paths = [
      'mmap2.dll', // Same directory as executable
      'lib/mmap2.dll', // In lib subdirectory
    ];

    for (final path in paths) {
      try {
        return ffi.DynamicLibrary.open(path);
      } catch (e) {
        // Continue trying other paths
      }
    }

    throw StateError(
      'Could not load mio_wrapper.dll. For Windows desktop applications:\n'
      '1. Place mio_wrapper.dll next to your application executable\n'
      '2. Or add the library location to your PATH environment variable\n'
      '3. Or install the library in a system directory',
    );
  }

  static ffi.DynamicLibrary loadMacOSLibrary() {
    // For macOS desktop, try multiple strategies:
    // 1. App bundle (for packaged apps)
    // 2. Adjacent to executable
    // 3. System library paths
    final paths = [
      'libmmap2.dylib', // Same directory as executable
      '@executable_path/libmmap2.dylib', // Relative to executable
      '@loader_path/libmmap2.dylib', // Relative to loading binary
      '/usr/local/lib/libmmap2.dylib', // Homebrew location
      '/opt/homebrew/lib/libmmap2.dylib', // Apple Silicon Homebrew
    ];

    for (final path in paths) {
      try {
        return ffi.DynamicLibrary.open(path);
      } catch (e) {
        // Continue trying other paths
      }
    }

    throw StateError(
      'Could not load libmio_wrapper.dylib. For macOS desktop applications:\n'
      '1. Place libmio_wrapper.dylib next to your application executable\n'
      '2. Or install via Homebrew: brew install <your-formula>\n'
      '3. Or set DYLD_LIBRARY_PATH environment variable',
    );
  }

  static ffi.DynamicLibrary loadLinuxLibrary() {
    // For Linux desktop, try multiple strategies:
    // 1. Adjacent to executable
    // 2. LD_LIBRARY_PATH
    // 3. System library directories
    final paths = [
      'libmmap2.so', // Same directory as executable
      './libmmap2.so', // Current directory
      '/usr/local/lib/libmmap2.so', // Common install location
      '/usr/lib/libmmap2.so', // System library directory
      '/usr/lib/x86_64-linux-gnu/libmmap2.so', // Debian/Ubuntu
    ];

    for (final path in paths) {
      try {
        return ffi.DynamicLibrary.open(path);
      } catch (e) {
        // Continue trying other paths
      }
    }

    throw StateError(
      'Could not load libmio_wrapper.so. For Linux desktop applications:\n'
      '1. Place libmio_wrapper.so next to your application executable\n'
      '2. Or install to /usr/local/lib/ and run ldconfig\n'
      '3. Or set LD_LIBRARY_PATH environment variable\n'
      '4. Or install via package manager',
    );
  }
}
