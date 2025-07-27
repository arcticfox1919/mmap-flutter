/// Exception thrown by mmap operations
class MmapException implements Exception {
  /// The error message
  final String message;

  /// The error code from the native library
  final int errorCode;

  const MmapException(this.message, this.errorCode);

  @override
  String toString() => 'MmapException: $message (code: $errorCode)';
}

/// Exception thrown when a file is not found
class FileNotFoundException extends MmapException {
  const FileNotFoundException(String message, int errorCode)
    : super(message, errorCode);
}

/// Exception thrown when permission is denied
class PermissionDeniedException extends MmapException {
  const PermissionDeniedException(String message, int errorCode)
    : super(message, errorCode);
}

/// Exception thrown when out of memory
class OutOfMemoryException extends MmapException {
  const OutOfMemoryException(String message, int errorCode)
    : super(message, errorCode);
}

/// Exception thrown when memory mapping fails
class MappingFailedException extends MmapException {
  const MappingFailedException(String message, int errorCode)
    : super(message, errorCode);
}

/// Exception thrown when an invalid handle is used
class InvalidHandleException extends MmapException {
  const InvalidHandleException(String message, int errorCode)
    : super(message, errorCode);
}
