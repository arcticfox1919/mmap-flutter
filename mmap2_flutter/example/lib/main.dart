import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:mmap2_flutter/mmap2_flutter.dart';
import 'package:mmap2/mmap2.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Not initialized';
  String _fileContent = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeMmap();
  }

  Future<void> _initializeMmap() async {
    try {
      setState(() {
        _status = 'Initializing...';
      });

      await MmapFlutter.initialize();

      setState(() {
        _status = 'Initialized successfully';
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _isInitialized = false;
      });
    }
  }

  Future<void> _testMemoryMapRead() async {
    try {
      setState(() {
        _status = 'Creating test file for reading...';
      });

      // Get app documents directory for the test file
      final testContent =
          'Hello from Flutter Memory Map!\n'
          'Platform: ${Platform.operatingSystem}\n'
          'Time: ${DateTime.now()}';

      final testFile = File(
        '${Directory.systemTemp.path}/flutter_mmap_read_test.txt',
      );
      await testFile.writeAsString(testContent);

      setState(() {
        _status = 'Memory mapping file for reading...';
      });

      // Create memory map for reading
      final mmap = Mmap.fromFile(testFile.path, mode: AccessMode.read);

      // Read data
      final data = mmap.data;
      final content = String.fromCharCodes(data);

      setState(() {
        _status = 'Read memory map successful!';
        _fileContent = 'READ TEST:\n$content';
      });

      // Clean up
      mmap.close();
      await testFile.delete();
    } catch (e) {
      debugPrint('Read test error: $e');
      setState(() {
        _status = 'Read test failed: $e';
        _fileContent = '';
      });
    }
  }

  Future<void> _testMemoryMapWrite() async {
    try {
      setState(() {
        _status = 'Creating test file for writing...';
      });

      // Create initial file with sufficient size for writing
      final initialContent =
          'Initial content for write test\n' +
          (' ' * 300); // Padding for write space
      final testFile = File(
        '${Directory.systemTemp.path}/flutter_mmap_write_test.txt',
      );
      await testFile.writeAsString(initialContent);

      setState(() {
        _status = 'Memory mapping file for writing...';
      });

      // Create memory map for writing
      final mmap = Mmap.fromFile(testFile.path, mode: AccessMode.write);

      setState(() {
        _status = 'Writing data via memory map...';
      });

      // Prepare new content to write
      final newContent =
          'MODIFIED by Memory Map!\n'
          'Platform: ${Platform.operatingSystem}\n'
          'Write Time: ${DateTime.now()}\n'
          'Test successful!';

      final bytes = newContent.codeUnits;
      final data = mmap.writableData; // Use writableData for write operations

      // Ensure we don't write beyond the mapped region
      final bytesToWrite = bytes.length < data.length
          ? bytes.length
          : data.length;

      // Write the new content to the beginning of the mapped memory
      for (int i = 0; i < bytesToWrite; i++) {
        data[i] = bytes[i];
      }

      // Sync changes to disk
      mmap.sync();

      setState(() {
        _status = 'Reading back written data...';
      });

      // Read back the data to verify the write was successful
      final verificationData = mmap.data; // Use read-only data for verification
      final readBackBytes = verificationData.take(bytesToWrite).toList();
      final readBackContent = String.fromCharCodes(readBackBytes);

      setState(() {
        _status = 'Write memory map successful!';
        _fileContent = 'WRITE TEST RESULT:\n$readBackContent';
      });

      // Clean up
      mmap.close();
      await testFile.delete();
    } catch (e) {
      debugPrint('Write test error: $e');
      setState(() {
        _status = 'Write test failed: $e';
        _fileContent = 'Write test error details:\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Mmap2 Flutter Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: $_status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _testMemoryMapRead : null,
                      child: const Text('Test Read'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isInitialized ? _testMemoryMapWrite : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Test Write'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_fileContent.isNotEmpty) ...[
                Text(
                  'File Content:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _fileContent,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
