import 'dart:io';
import 'package:mmap2/mmap2.dart';

void main() async {
  // Initialize the library using the cross-platform helper
  try {
    Mmap.initializePlatform();
  } catch (e) {
    print('Failed to load mmap library: $e');
    print('Make sure the native library is built and available in the PATH.');
    return;
  }

  // Create a test file
  final testFile = File('test_file.txt');
  await testFile.writeAsString(
    'Hello, Memory Mapped World!\nThis is a test file.',
  );

  try {
    // Example 1: Read-only memory mapping
    print('=== Read-only Memory Mapping ===');
    final readMmap = Mmap.fromFile(testFile.path, mode: AccessMode.read);

    print('File size: ${readMmap.size} bytes');
    print('Mapped length: ${readMmap.mappedLength} bytes');
    print('Is open: ${readMmap.isOpen}');
    print('Is mapped: ${readMmap.isMapped}');
    print('Access mode: ${readMmap.accessMode}');

    // Read the data
    final data = readMmap.data;
    final content = String.fromCharCodes(data);
    print('Content: $content');

    readMmap.close();

    // Example 2: Write-enabled memory mapping
    print('\n=== Write-enabled Memory Mapping ===');
    final writeMmap = Mmap.fromFile(testFile.path, mode: AccessMode.write);

    // Get writable data and modify it
    final writableData = writeMmap.writableData;
    final originalContent = String.fromCharCodes(writableData);
    print('Original content: $originalContent');

    // Modify the content (change 'Hello' to 'HELLO')
    for (int i = 0; i < 5 && i < writableData.length; i++) {
      if (writableData[i] >= 97 && writableData[i] <= 122) {
        // lowercase
        writableData[i] = writableData[i] - 32; // convert to uppercase
      }
    }

    // Sync changes to disk
    writeMmap.sync();
    print('Modified and synced to disk');

    writeMmap.close();

    // Verify the changes
    print('\n=== Verification ===');
    final finalContent = await testFile.readAsString();
    print('Final content: $finalContent');
  } catch (e) {
    print('Error: $e');
  } finally {
    // Clean up
    if (await testFile.exists()) {
      await testFile.delete();
    }
  }
}
