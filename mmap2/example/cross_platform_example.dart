import 'dart:io';
import 'package:mmap2/mmap2.dart';

void main() async {
  print('=== Mmap Cross-Platform Example ===');

  // Initialize the library using the platform-specific helper
  try {
    // await MmapFlutter.initialize();
    print('✓ Mmap library initialized successfully');
  } catch (e) {
    print('✗ Failed to initialize Mmap library: $e');
    print('Make sure the native library is built and available.');
    return;
  }

  // Create a test file
  final testFile = File('cross_platform_test.txt');
  await testFile.writeAsString('Hello from ${Platform.operatingSystem}!\n');
  print('✓ Created test file: ${testFile.path}');

  try {
    // Example 1: Read-only memory mapping
    print('\n--- Read-only Memory Mapping ---');
    final readMmap = Mmap.fromFile(testFile.path, mode: AccessMode.read);

    print('File size: ${readMmap.size} bytes');
    print('Mapped length: ${readMmap.mappedLength} bytes');
    print('Platform: ${Platform.operatingSystem}');
    print('Architecture: ${Platform.version}');

    // Read the data
    final data = readMmap.data;
    final content = String.fromCharCodes(data);
    print('Content: ${content.trim()}');

    readMmap.close();
    print('✓ Read-only mapping completed');

    // Example 2: Write-enabled memory mapping (if supported on platform)
    print('\n--- Write-enabled Memory Mapping ---');
    try {
      final writeMmap = Mmap.fromFile(testFile.path, mode: AccessMode.write);

      // Get writable data and append platform info
      final writableData = writeMmap.writableData;
      final platformInfo = 'Modified on ${Platform.operatingSystem}';
      final platformBytes = platformInfo.codeUnits;

      // Find the end of the file and append (if there's space)
      int writePos = writableData.length;
      for (int i = 0; i < writableData.length; i++) {
        if (writableData[i] == 0) {
          writePos = i;
          break;
        }
      }

      // Append platform info if there's space
      if (writePos + platformBytes.length < writableData.length) {
        for (int i = 0; i < platformBytes.length; i++) {
          writableData[writePos + i] = platformBytes[i];
        }
      }

      // Sync changes to disk
      writeMmap.sync();
      print('✓ Write operation completed and synced');

      writeMmap.close();
    } catch (e) {
      print('Write operation failed: $e');
      print('This might be expected on some platforms or file systems');
    }

    // Example 3: Platform-specific features
    print('\n--- Platform-specific Information ---');
    print('Operating System: ${Platform.operatingSystem}');
    print('OS Version: ${Platform.operatingSystemVersion}');
    print('Number of processors: ${Platform.numberOfProcessors}');
    print('Executable: ${Platform.executable}');

    if (Platform.isAndroid || Platform.isIOS) {
      print('Running on mobile platform - memory mapping may have limitations');
    } else {
      print('Running on desktop platform - full memory mapping support');
    }
  } catch (e) {
    print('Error during memory mapping operations: $e');
    if (e is MmapException) {
      print('Error code: ${e.errorCode}');
    }
  } finally {
    // Clean up
    if (await testFile.exists()) {
      await testFile.delete();
      print('✓ Cleaned up test file');
    }
  }

  print('\n=== Example completed ===');
}
