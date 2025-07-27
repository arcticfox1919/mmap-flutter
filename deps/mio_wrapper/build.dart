#!/usr/bin/env dart

import 'dart:io';

void main(List<String> args) {
  final builder = NativeLibraryBuilder();
  builder.run(args);
}

class NativeLibraryBuilder {
  static const String defaultVersion = '1.0.0';

  void run(List<String> args) {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      _showHelp();
      return;
    }

    final config = _parseArgs(args);

    print('🚀 Building mmap2 native libraries...');
    print('📋 Configuration:');
    print('   Version: ${config.version}');
    print('   Platforms: ${config.platforms.join(', ')}');
    print('   Build Type: ${config.buildType}');
    print('   Clean: ${config.clean}');
    print('   Install: ${config.install}');
    print('');

    if (config.clean) {
      _cleanBuild();
    }

    for (final platform in config.platforms) {
      try {
        _buildPlatform(platform, config);
      } catch (e) {
        print('❌ Failed to build $platform: $e');
        exit(1);
      }
    }

    print('');
    print('🎉 Build completed successfully!');
  }

  BuildConfig _parseArgs(List<String> args) {
    final config = BuildConfig();

    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--version':
          if (i + 1 < args.length) {
            config.version = args[++i];
          }
          break;
        case '--platform':
          if (i + 1 < args.length) {
            final platform = args[++i];
            if (_isValidPlatform(platform)) {
              config.platforms = [platform];
            } else {
              print('❌ Invalid platform: $platform');
              exit(1);
            }
          }
          break;
        case '--all':
          config.platforms = _getAllPlatforms();
          break;
        case '--clean':
          config.clean = true;
          break;
        case '--install':
          config.install = true;
          break;
        case '--debug':
          config.buildType = 'Debug';
          break;
        case '--release':
          config.buildType = 'Release';
          break;
        default:
          if (_isValidPlatform(args[i])) {
            config.platforms = [args[i]];
          }
          break;
      }
    }

    return config;
  }

  void _buildPlatform(String platform, BuildConfig config) {
    print('🔨 Building for $platform...');

    switch (platform) {
      case 'android':
        _buildAndroid(config);
        break;
      case 'ios':
        _buildIOS(config);
        break;
      case 'macos':
        _buildDesktop(platform, config);
        break;
      case 'windows':
        _buildDesktop(platform, config);
        break;
      case 'linux':
        _buildDesktop(platform, config);
        break;
      default:
        throw Exception('Unsupported platform: $platform');
    }

    print('✅ $platform build completed');
  }

  void _buildAndroid(BuildConfig config) {
    final ndk = _ensureAndroidNDK();
    final ninjaPath = _ensureNinja();

    final abis = ['arm64-v8a', 'armeabi-v7a', 'x86_64'];
    const minSdkVersion = 21;

    for (final abi in abis) {
      print('  📱 Building Android $abi...');

      final buildDir = 'build/android/${config.buildType}/$abi';
      _runCMakeConfigureAndBuild(buildDir, [
        '-G',
        'Ninja',
        '-DCMAKE_SYSTEM_NAME=Android',
        '-DCMAKE_SYSTEM_VERSION=$minSdkVersion',
        '-DANDROID_PLATFORM=android-$minSdkVersion',
        '-DCMAKE_ANDROID_ARCH_ABI=$abi',
        '-DANDROID_ABI=$abi',
        '-DCMAKE_ANDROID_NDK=$ndk',
        '-DCMAKE_TOOLCHAIN_FILE=$ndk/build/cmake/android.toolchain.cmake',
        '-DCMAKE_MAKE_PROGRAM=$ninjaPath',
      ], config);
    }

    // Install to Flutter plugin if requested
    if (config.install) {
      _installAndroidLibraries(config, abis);
    }
  }

  void _installAndroidLibraries(BuildConfig config, List<String> abis) {
    print('  📦 Installing Android libraries to Flutter plugin...');

    // Navigate to the Flutter plugin jniLibs directory
    final jniLibsPath = '../../mmap2_flutter/android/src/main/jniLibs';
    final jniLibsDir = Directory(jniLibsPath);

    // Create jniLibs directory if it doesn't exist
    if (!jniLibsDir.existsSync()) {
      jniLibsDir.createSync(recursive: true);
      print('    📁 Created jniLibs directory: $jniLibsPath');
    }

    for (final abi in abis) {
      final buildDir = 'build/android/${config.buildType}/$abi';
      final sourceLib = '$buildDir/libmmap2.so';

      if (!File(sourceLib).existsSync()) {
        print('    ⚠️ Warning: Library not found at $sourceLib for $abi');
        continue;
      }

      // Create ABI-specific directory
      final abiDir = Directory('$jniLibsPath/$abi');
      if (!abiDir.existsSync()) {
        abiDir.createSync(recursive: true);
      }

      // Copy library to jniLibs
      final destLib = '$jniLibsPath/$abi/libmmap2.so';
      File(sourceLib).copySync(destLib);
      print('    ✅ Installed $abi: $destLib');
    }

    print('  🎉 Android libraries installation completed!');
  }

  void _installIOSFramework(BuildConfig config) {
    print('  📦 Installing iOS XCFramework to Flutter plugin...');

    final sourceFramework = 'dist/ios/mmap2.xcframework';
    final destPath = '../../mmap2_flutter/ios/mmap2.xcframework';

    if (!Directory(sourceFramework).existsSync()) {
      print('    ⚠️ Warning: XCFramework not found at $sourceFramework');
      return;
    }

    // Remove existing framework if it exists
    final destDir = Directory(destPath);
    if (destDir.existsSync()) {
      destDir.deleteSync(recursive: true);
      print('    🗑️ Removed existing XCFramework');
    }

    // Create parent directory if needed
    final parentDir = Directory(destPath).parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    // Copy XCFramework recursively
    _copyDirectory(Directory(sourceFramework), destDir);
    print('    ✅ Installed iOS XCFramework: $destPath');
    print('  🎉 iOS XCFramework installation completed!');
  }

  void _copyDirectory(Directory source, Directory dest) {
    if (!dest.existsSync()) {
      dest.createSync(recursive: true);
    }

    for (final entity in source.listSync()) {
      if (entity is File) {
        final newFile = File(
          '${dest.path}/${entity.path.split(Platform.pathSeparator).last}',
        );
        entity.copySync(newFile.path);
      } else if (entity is Directory) {
        final newDir = Directory(
          '${dest.path}/${entity.path.split(Platform.pathSeparator).last}',
        );
        _copyDirectory(entity, newDir);
      }
    }
  }

  void _buildIOS(BuildConfig config) {
    if (!Platform.isMacOS) {
      throw Exception('iOS builds can only be performed on macOS');
    }

    _ensureXcode();

    print('  🍎 Building iOS libraries for multiple architectures...');

    // Define iOS architectures: arm64 device, arm64 simulator, x86_64 simulator
    final iosArchs = [
      {
        'platform': 'OS64',
        'arch': 'arm64',
        'name': 'device',
        'sdk': 'iphoneos',
      },
      {
        'platform': 'SIMULATORARM64',
        'arch': 'arm64',
        'name': 'simulator-arm64',
        'sdk': 'iphonesimulator',
      },
      {
        'platform': 'SIMULATOR64',
        'arch': 'x86_64',
        'name': 'simulator-x64',
        'sdk': 'iphonesimulator',
      },
    ];

    final builtLibraries = <Map<String, String>>[];

    // Build each architecture separately
    for (final archConfig in iosArchs) {
      final platform = archConfig['platform']!;
      final arch = archConfig['arch']!;
      final name = archConfig['name']!;
      final sdk = archConfig['sdk']!;

      print('    📱 Building iOS $name ($arch)...');

      final buildDir = 'build/ios-cache/$name';
      final toolchainPath = '${Directory.current.path}/cmake/ios-cmake/ios.toolchain.cmake';
      _runCMakeConfigureAndBuild(buildDir, [
        '-G',
        'Xcode',
        '-DCMAKE_TOOLCHAIN_FILE=$toolchainPath',
        '-DPLATFORM=$platform',
        '-DARCHS=$arch',
        '-DDEPLOYMENT_TARGET=13.0',
      ], config);

      // Find the built library
      final libPath = _findIOSLibrary(buildDir, config.buildType);
      if (libPath != null) {
        builtLibraries.add({
          'path': libPath,
          'arch': arch,
          'sdk': sdk,
          'name': name,
        });
        print('    ✅ Built: $libPath');
      } else {
        throw Exception('Failed to find built library for iOS $name');
      }
    }

    // Create XCFramework instead of Fat library
    if (builtLibraries.isNotEmpty) {
      _createXCFramework(builtLibraries, config);

      // Install to Flutter plugin if requested
      if (config.install) {
        _installIOSFramework(config);
      }
    }
  }

  String? _findIOSLibrary(String buildDir, String buildType) {
    // Look for the built framework in common paths
    final possiblePaths = [
      '$buildDir/$buildType-iphoneos/mmap2.framework',
      '$buildDir/$buildType-iphonesimulator/mmap2.framework',
      '$buildDir/$buildType/mmap2.framework',
      '$buildDir/mmap2.framework',
    ];

    for (final path in possiblePaths) {
      if (Directory(path).existsSync()) {
        return path;
      }
    }

    // Recursive search as fallback
    final dir = Directory(buildDir);
    if (!dir.existsSync()) return null;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is Directory && entity.path.endsWith('mmap2.framework')) {
        return entity.path;
      }
    }

    return null;
  }

  void _createXCFramework(
    List<Map<String, String>> libraries,
    BuildConfig config,
  ) {
    print('    🔗 Creating XCFramework following Apple standards...');

    final outputDir = Directory('dist/ios');
    
    // Always clean the output directory first
    if (outputDir.existsSync()) {
      outputDir.deleteSync(recursive: true);
      print('    🗑️ Cleaned dist/ios directory');
    }
    outputDir.createSync(recursive: true);

    final xcframeworkPath = '${outputDir.path}/mmap2.xcframework';

    // Step 1: Find the actual framework paths (not .a files)
    final deviceFrameworkPath = 'build/ios-cache/device/Release-iphoneos/mmap2.framework';
    final simArm64FrameworkPath = 'build/ios-cache/simulator-arm64/Release-iphonesimulator/mmap2.framework';
    final simX64FrameworkPath = 'build/ios-cache/simulator-x64/Release-iphonesimulator/mmap2.framework';

    // Verify all frameworks exist
    if (!Directory(deviceFrameworkPath).existsSync()) {
      throw Exception('Device framework not found: $deviceFrameworkPath');
    }
    if (!Directory(simArm64FrameworkPath).existsSync()) {
      throw Exception('Simulator arm64 framework not found: $simArm64FrameworkPath');
    }
    if (!Directory(simX64FrameworkPath).existsSync()) {
      throw Exception('Simulator x86_64 framework not found: $simX64FrameworkPath');
    }

    // Step 2: Create unified simulator framework (fat binary for arm64 + x86_64)
    final unifiedSimFrameworkPath = '${outputDir.path}/mmap2.framework';
    print('    📱 Creating unified simulator framework...');
    
    // Copy arm64 simulator framework as base
    Process.runSync('cp', ['-R', simArm64FrameworkPath, unifiedSimFrameworkPath]);
    
    // Create fat binary combining arm64 and x86_64 simulator binaries
    final lipoResult = Process.runSync('lipo', [
      '-create',
      '$simArm64FrameworkPath/mmap2',
      '$simX64FrameworkPath/mmap2',
      '-output',
      '$unifiedSimFrameworkPath/mmap2',
    ]);
    
    if (lipoResult.exitCode != 0) {
      throw Exception('Failed to create simulator fat binary: ${lipoResult.stderr}');
    }

    // Step 3: Create XCFramework using the device framework and unified simulator framework
    print('    📦 Creating XCFramework...');
    final xcodebuildArgs = [
      '-create-xcframework',
      '-framework', deviceFrameworkPath,
      '-framework', unifiedSimFrameworkPath,
      '-output', xcframeworkPath,
    ];

    final result = Process.runSync('xcodebuild', xcodebuildArgs);
    if (result.exitCode != 0) {
      throw Exception('Failed to create XCFramework: ${result.stderr}');
    }

    print('    ✅ XCFramework created: $xcframeworkPath');

    // Clean up temporary unified simulator framework
    final unifiedSimDir = Directory(unifiedSimFrameworkPath);
    if (unifiedSimDir.existsSync()) {
      unifiedSimDir.deleteSync(recursive: true);
    }

    // Show XCFramework info for verification
    final infoResult = Process.runSync('xcodebuild', [
      '-list',
      '-xcframework',
      xcframeworkPath,
    ]);
    if (infoResult.exitCode == 0) {
      print('    📋 XCFramework contents:');
      print(infoResult.stdout);
    }
  }

  void _buildDesktop(String platform, BuildConfig config) {
    final platformSettings = _getDesktopPlatformSettings(platform);

    print(
      '  ${platformSettings['icon']} Building $platform ${platformSettings['arch']} library...',
    );

    final buildDir = 'build/$platform-${platformSettings['arch']}';
    final extraArgs = List<String>.from(platformSettings['cmakeArgs'] as List);
    extraArgs.add('-DBUILD_SHARED_LIBS=ON');

    _runCMakeConfigureAndBuild(buildDir, extraArgs, config);

    // Run package target to create ZIP
    _runCMakeTarget(buildDir, 'package', config);
  }

  void _runCMakeConfigureAndBuild(
    String buildDir,
    List<String> extraArgs,
    BuildConfig config,
  ) {
    // Ensure build directory exists
    final dir = Directory(buildDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // Configure
    final configureArgs = [
      '-B',
      buildDir,
      '-DCMAKE_BUILD_TYPE=${config.buildType}',
      '-DPROJECT_VERSION=${config.version}',
      ...extraArgs,
      '.',
    ];

    final configureResult = Process.runSync('cmake', configureArgs);
    if (configureResult.exitCode != 0) {
      print('CMake configure output: ${configureResult.stdout}');
      print('CMake configure error: ${configureResult.stderr}');
      throw Exception(
        'CMake configure failed with exit code ${configureResult.exitCode}',
      );
    }

    // Build
    final buildResult = Process.runSync('cmake', [
      '--build',
      buildDir,
      '--config',
      config.buildType,
      '--parallel',
    ]);

    if (buildResult.exitCode != 0) {
      print('Build output: ${buildResult.stdout}');
      print('Build error: ${buildResult.stderr}');
      throw Exception('Build failed with exit code ${buildResult.exitCode}');
    }
  }

  void _runCMakeTarget(String buildDir, String target, BuildConfig config) {
    final result = Process.runSync('cmake', [
      '--build',
      buildDir,
      '--target',
      target,
      '--config',
      config.buildType,
    ]);

    if (result.exitCode != 0) {
      print(
        '⚠️ Warning: $target target failed with exit code ${result.exitCode}',
      );
      print('Target output: ${result.stdout}');
      print('Target error: ${result.stderr}');
    } else {
      print('✅ $target target completed successfully');
      if (result.stdout.isNotEmpty) {
        print('Target output: ${result.stdout}');
      }

      // For package target, move ZIP to release directory
      if (target == 'package') {
        _movePackageToRelease(buildDir, config);
      }
    }
  }

  void _movePackageToRelease(String buildDir, BuildConfig config) {
    final buildDirectory = Directory(buildDir);
    if (!buildDirectory.existsSync()) return;

    // Create release directory
    final releaseDir = Directory('release');
    if (!releaseDir.existsSync()) {
      releaseDir.createSync(recursive: true);
      print('📁 Created release directory');
    }

    // Look for ZIP files in build directory
    for (final entity in buildDirectory.listSync()) {
      if (entity is File && entity.path.endsWith('.zip')) {
        // Use path.basename to get filename in a cross-platform way
        final fileName = entity.path.split(Platform.pathSeparator).last;
        final destPath = '${releaseDir.path}${Platform.pathSeparator}$fileName';

        entity.copySync(destPath);
        print('📦 Package moved to release: $destPath');
        break;
      }
    }
  }

  Map<String, dynamic> _getDesktopPlatformSettings(String platform) {
    switch (platform) {
      case 'macos':
        if (!Platform.isMacOS) {
          throw Exception('macOS builds can only be performed on macOS');
        }
        return {
          'icon': '🖥️',
          'arch': 'universal',
          'cmakeArgs': [
            '-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15',
            '-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64',
          ],
        };
      case 'windows':
        if (!Platform.isWindows) {
          throw Exception('Windows builds can only be performed on Windows');
        }
        return {
          'icon': '🪟',
          'arch': 'x64',
          'cmakeArgs': ['-G', 'Visual Studio 17 2022', '-A', 'x64'],
        };
      case 'linux':
        if (!Platform.isLinux) {
          throw Exception('Linux builds can only be performed on Linux');
        }
        return {'icon': '🐧', 'arch': 'x86_64', 'cmakeArgs': <String>[]};
      default:
        throw Exception('Unsupported desktop platform: $platform');
    }
  }

  void _cleanBuild() {
    print('🧹 Cleaning build directories...');

    final dirs = ['build', 'release'];
    for (final dirName in dirs) {
      final dir = Directory(dirName);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        print('  🗑️ Removed $dirName/');
      }
    }
  }

  String _ensureAndroidNDK() {
    final ndkRoot = Platform.environment['ANDROID_NDK_ROOT'];
    if (ndkRoot == null || ndkRoot.isEmpty) {
      throw Exception('ANDROID_NDK_ROOT environment variable is not set');
    }

    if (!Directory(ndkRoot).existsSync()) {
      throw Exception('Android NDK not found at: $ndkRoot');
    }

    return ndkRoot;
  }

  String _ensureNinja() {
    // First try environment variable
    final ninjaPath = Platform.environment['NINJA_PATH'];
    if (ninjaPath != null &&
        ninjaPath.isNotEmpty &&
        File(ninjaPath).existsSync()) {
      return ninjaPath;
    }

    // Fallback to PATH
    try {
      final result = Process.runSync('where', ['ninja']);
      if (result.exitCode == 0) {
        final paths = result.stdout.toString().trim().split('\n');
        if (paths.isNotEmpty) {
          return paths.first.trim();
        }
      }
    } catch (e) {
      print(e);
    }
    return '';
  }

  void _ensureXcode() {
    final result = Process.runSync('xcodebuild', ['-version']);
    if (result.exitCode != 0) {
      throw Exception('Xcode is not installed or xcodebuild is not in PATH');
    }
  }

  bool _isValidPlatform(String platform) {
    return ['android', 'ios', 'macos', 'windows', 'linux'].contains(platform);
  }

  List<String> _getAllPlatforms() {
    final platforms = <String>[];

    // Always add current platform
    if (Platform.isAndroid) platforms.add('android');
    if (Platform.isIOS) platforms.add('ios');
    if (Platform.isMacOS) platforms.addAll(['macos', 'ios']);
    if (Platform.isWindows) platforms.add('windows');
    if (Platform.isLinux) platforms.addAll(['linux', 'android']);

    return platforms.isNotEmpty
        ? platforms
        : ['android', 'ios', 'macos', 'windows', 'linux'];
  }

  void _showHelp() {
    print('''
🚀 mmap2 Native Library Builder

Usage: dart build.dart [options] [platform]

Options:
  --version <version>    Set library version (default: $defaultVersion)
  --platform <platform>  Build specific platform
  --all                  Build all supported platforms for current OS
  --clean               Clean build directories before building
  --install             Install built libraries to Flutter plugin (Android/iOS only)
  --debug               Build in Debug mode (default: Release)
  --release             Build in Release mode
  --help, -h            Show this help

Platforms:
  android               Build Android libraries (all ABIs)
  ios                   Build iOS XCFramework (device + simulator)
  macos                 Build macOS universal dynamic library
  windows               Build Windows x64 dynamic library
  linux                 Build Linux x86_64 dynamic library

Examples:
  dart build.dart android                    # Build Android libraries
  dart build.dart android --install          # Build and install Android libraries
  dart build.dart ios --install              # Build and install iOS XCFramework
  dart build.dart --all                      # Build all platforms for current OS
  dart build.dart --version 1.2.0 macos     # Build macOS with custom version
  dart build.dart --clean --debug ios       # Clean build iOS in debug mode

Environment Variables:
  ANDROID_NDK_ROOT      Path to Android NDK (required for Android builds)

Output:
  Desktop platforms:    ZIP packages created in release/ directory
  Mobile platforms:     Libraries built in build/<platform>/ directories
  iOS:                  XCFramework created in dist/ios/mmap2.xcframework
  Android (--install):  Libraries copied to mmap2_flutter/android/src/main/jniLibs/
  iOS (--install):      XCFramework copied to mmap2_flutter/ios/mmap2.xcframework
''');
  }
}

class BuildConfig {
  String version = NativeLibraryBuilder.defaultVersion;
  List<String> platforms = [];
  String buildType = 'Release';
  bool clean = false;
  bool install = false;

  BuildConfig() {
    // Default to current platform if none specified
    if (Platform.isMacOS)
      platforms = ['macos'];
    else if (Platform.isWindows)
      platforms = ['windows'];
    else if (Platform.isLinux)
      platforms = ['linux'];
  }
}
