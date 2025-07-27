import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:mmap2/mmap2.dart';

void main() {
  late File testFile;

  setUpAll(() async {
    // Initialize the library (skip if library not available)
    try {
      Mmap.setLibraryLoader(() {
        return ffi.DynamicLibrary.open('mmap2 path');
      });
      Mmap.initializePlatform();
    } catch (e) {
      print('Warning: Could not load mmap library: $e');
      print(
        'Tests will be skipped. Make sure to build the native library first.',
      );
    }
  });

  setUp(() async {
    testFile = File('test_${DateTime.now().millisecondsSinceEpoch}.txt');
    await testFile.writeAsString('Hello, World!');
  });

  tearDown(() async {
    if (await testFile.exists()) {
      await testFile.delete();
    }
  });

  group('Mmap Tests', () {
    test('read-only memory mapping', () async {
      try {
        final mmap = Mmap.fromFile(testFile.path, mode: AccessMode.read);

        expect(mmap.isOpen, isTrue);
        expect(mmap.isMapped, isTrue);
        expect(mmap.accessMode, equals(AccessMode.read));
        expect(mmap.size, greaterThan(0));

        final data = mmap.data;
        final content = String.fromCharCodes(data);
        expect(content, equals('Hello, World!'));

        mmap.close();
        expect(mmap.isOpen, isFalse);
      } catch (e) {
        // Skip test if library not available
        if (e.toString().contains('not initialized')) {
          return;
        }
        rethrow;
      }
    });

    test('write-enabled memory mapping', () async {
      try {
        final mmap = Mmap.fromFile(testFile.path, mode: AccessMode.write);

        expect(mmap.accessMode, equals(AccessMode.write));

        final writableData = mmap.writableData;
        expect(writableData, isA<Uint8List>());

        // Modify the first character
        writableData[0] = 'h'.codeUnitAt(0);

        mmap.sync();
        mmap.close();

        // Verify the change
        final content = await testFile.readAsString();
        expect(content, equals('hello, World!'));
      } catch (e) {
        // Skip test if library not available
        if (e.toString().contains('not initialized')) {
          return;
        }
        rethrow;
      }
    });

    test('file not found exception', () {
      try {
        expect(
          () => Mmap.fromFile('nonexistent_file.txt'),
          throwsA(isA<FileNotFoundException>()),
        );
      } catch (e) {
        // Skip test if library not available
        if (e.toString().contains('not initialized')) {
          return;
        }
        rethrow;
      }
    });

    test('cannot get writable data from read-only map', () async {
      try {
        final mmap = Mmap.fromFile(testFile.path, mode: AccessMode.read);

        expect(() => mmap.writableData, throwsA(isA<StateError>()));

        mmap.close();
      } catch (e) {
        // Skip test if library not available
        if (e.toString().contains('not initialized')) {
          return;
        }
        rethrow;
      }
    });

    test('cannot sync read-only map', () async {
      try {
        final mmap = Mmap.fromFile(testFile.path, mode: AccessMode.read);

        expect(() => mmap.sync(), throwsA(isA<StateError>()));

        mmap.close();
      } catch (e) {
        // Skip test if library not available
        if (e.toString().contains('not initialized')) {
          return;
        }
        rethrow;
      }
    });
  });
}
