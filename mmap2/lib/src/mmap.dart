import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'mmap_exception.dart';
import 'mio_wrapper_bindings.dart';

/// Access mode for memory mapping
enum AccessMode {
  /// Read-only access
  read,

  /// Read-write access
  write,
}

/// Special value to indicate mapping the entire file
const int mapEntireFile = 0;

/// A memory-mapped file
class Mmap {
  static late final MioBindings _bindings;
  static bool _initialized = false;
  static ffi.DynamicLibrary Function()? _customLibraryLoader;

  final ffi.Pointer<MioMmapHandle> _handle;
  final AccessMode _accessMode;

  Mmap._(this._handle, this._accessMode);

  /// Set a custom library loader function
  /// This allows external callers to control how the dynamic library is loaded
  static void setLibraryLoader(ffi.DynamicLibrary Function()? loader) {
    _customLibraryLoader = loader;
  }

  /// Clear the custom library loader, reverting to default platform detection
  static void clearLibraryLoader() {
    _customLibraryLoader = null;
  }

  /// Get the library version string
  /// Returns version string in format "major.minor.patch"
  static String getVersion() {
    _ensureInitialized();
    final versionPtr = _bindings.mio_get_version();
    if (versionPtr == ffi.nullptr) {
      throw StateError('Failed to get version information');
    }
    return versionPtr.cast<Utf8>().toDartString();
  }

  /// Initialize the library with the dynamic library
  static void initialize(ffi.DynamicLibrary library) {
    _bindings = MioBindings(library);
    _initialized = true;
  }

  /// Initialize the library with automatic platform detection
  /// Uses custom loader if set, otherwise falls back to default platform detection
  static void initializePlatform() {
    final library = _customLibraryLoader?.call() ?? _loadLibrary();
    initialize(library);
  }

  /// Load the platform-specific dynamic library (default implementation)
  /// This is used as fallback when no custom library loader is set
  static ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('mmap2.dll');
    } else if (Platform.isLinux) {
      return ffi.DynamicLibrary.open('libmmap2.so');
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open('libmmap2.dylib');
    } else if (Platform.isAndroid) {
      return ffi.DynamicLibrary.open('libmmap2.so');
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.process();
    } else {
      throw UnsupportedError(
        'Platform ${Platform.operatingSystem} is not supported',
      );
    }
  }

  /// Create a memory map from a file path
  ///
  /// [path] - The path to the file to be memory mapped
  /// [mode] - Access mode (read or write)
  /// [offset] - Byte offset from the beginning of the file
  /// [length] - Number of bytes to map. If null or 0, maps the entire file
  ///           from the offset to the end of the file
  static Mmap fromFile(
    String path, {
    AccessMode mode = AccessMode.read,
    int offset = 0,
    int? length,
  }) {
    _ensureInitialized();

    return using((arena) {
      final pathPtr = path.toNativeUtf8(allocator: arena);
      final errorPtr = arena<ffi.UnsignedInt>();

      final accessMode = mode == AccessMode.read
          ? MioAccessMode.MIO_ACCESS_READ
          : MioAccessMode.MIO_ACCESS_WRITE;

      final handle = _bindings.mio_mmap_create_from_path(
        pathPtr.cast<ffi.Char>(),
        accessMode,
        offset,
        length ?? mapEntireFile,
        errorPtr,
      );

      final error = errorPtr.value;
      if (error != MioError.MIO_SUCCESS.value || handle == ffi.nullptr) {
        _throwException(error);
      }

      return Mmap._(handle, mode);
    });
  }

  /// Get the data as a Uint8List (read-only)
  Uint8List get data {
    _checkValid();
    final dataPtr = _bindings.mio_mmap_get_data(_handle);
    final size = _bindings.mio_mmap_get_size(_handle);

    if (dataPtr == ffi.nullptr) {
      throw StateError('Failed to get data pointer from memory map');
    }

    if (size == 0) {
      // For read-only data, zero size might be valid (empty file)
      // Return empty list but this is a legitimate case
      return Uint8List(0);
    }

    return dataPtr.asTypedList(size);
  }

  /// Get the data as a writable Uint8List (only for write-enabled maps)
  Uint8List get writableData {
    _checkValid();
    if (_accessMode != AccessMode.write) {
      throw StateError('Cannot get writable data from read-only memory map');
    }

    final dataPtr = _bindings.mio_mmap_get_data_writable(_handle);
    final size = _bindings.mio_mmap_get_size(_handle);

    if (dataPtr == ffi.nullptr) {
      throw StateError('Failed to get writable data pointer from memory map');
    }

    if (size == 0) {
      throw StateError(
        'Memory map has zero size, cannot provide writable data',
      );
    }

    return dataPtr.asTypedList(size);
  }

  /// Get the size of the mapped region in bytes
  int get size {
    _checkValid();
    return _bindings.mio_mmap_get_size(_handle);
  }

  /// Get the actual mapped length (may be larger due to page alignment)
  int get mappedLength {
    _checkValid();
    return _bindings.mio_mmap_get_mapped_length(_handle);
  }

  /// Check if the memory map is open
  bool get isOpen {
    if (_handle == ffi.nullptr) return false;
    return _bindings.mio_mmap_is_open(_handle) != 0;
  }

  /// Check if the memory map is mapped
  bool get isMapped {
    if (_handle == ffi.nullptr) return false;
    return _bindings.mio_mmap_is_mapped(_handle) != 0;
  }

  /// Get the access mode
  AccessMode get accessMode => _accessMode;

  /// Sync the memory map to disk (for write-enabled maps)
  void sync() {
    _checkValid();
    if (_accessMode != AccessMode.write) {
      throw StateError('Cannot sync read-only memory map');
    }

    final error = _bindings.mio_mmap_sync(_handle);
    if (error != MioError.MIO_SUCCESS) {
      _throwException(error.value);
    }
  }

  /// Close the memory map and free resources
  void close() {
    if (_handle != ffi.nullptr) {
      _bindings.mio_mmap_destroy(_handle);
    }
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'Mmap library not initialized. Call Mmap.initialize() first.',
      );
    }
  }

  void _checkValid() {
    if (_handle == ffi.nullptr) {
      throw StateError('Memory map has been closed');
    }
  }

  static Never _throwException(int errorCode) {
    final messagePtr = _bindings.mio_get_error_message(
      MioError.fromValue(errorCode),
    );
    final message = messagePtr.cast<Utf8>().toDartString();

    switch (MioError.fromValue(errorCode)) {
      case MioError.MIO_ERROR_FILE_NOT_FOUND:
        throw FileNotFoundException(message, errorCode);
      case MioError.MIO_ERROR_PERMISSION_DENIED:
        throw PermissionDeniedException(message, errorCode);
      case MioError.MIO_ERROR_OUT_OF_MEMORY:
        throw OutOfMemoryException(message, errorCode);
      case MioError.MIO_ERROR_MAPPING_FAILED:
        throw MappingFailedException(message, errorCode);
      case MioError.MIO_ERROR_INVALID_HANDLE:
        throw InvalidHandleException(message, errorCode);
      default:
        throw MmapException(message, errorCode);
    }
  }
}
