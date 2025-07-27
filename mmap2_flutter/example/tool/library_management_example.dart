#!/usr/bin/env dart

/// Example of using the mmap2_flutter native library management tool
///
/// This demonstrates how end users can easily set up and distribute
/// native libraries for their Flutter applications.

import 'dart:io';

void main() async {
  print('🚀 Mmap2 Flutter Library Management Example');
  print('');

  // Step 1: Check current status
  print('Step 1: Checking current status...');
  var result = await Process.run('dart', ['run', 'mmap2_flutter:check']);
  print(result.stdout);

  // Step 2: Show setup guide
  print('Step 2: Showing setup guide...');
  result = await Process.run('dart', ['run', 'mmap2_flutter:setup']);
  print(result.stdout);

  print('');
  print('✅ Example complete!');
  print('');
  print('Next steps for your project:');
  print(
    '1. Build native libraries: dart run scripts/build_native.dart <platform>',
  );
  print('2. Install for development: dart run mmap2_flutter:install');
  print('3. Bundle for distribution: dart run mmap2_flutter:bundle');
}
