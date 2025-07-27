# iOS Build Configuration

## Building Static Library for iOS

This directory structure supports building a universal static library for iOS that includes both device (arm64) and simulator (x86_64, arm64) architectures.

### Requirements

- Xcode with iOS SDK
- CMake 3.16+
- iOS deployment target: 12.0+

### Build Commands

```bash
# From mmap2_flutter directory
cmake -B build/ios \
      -S ../deps/mio_wrapper \
      -G Xcode \
      -DCMAKE_TOOLCHAIN_FILE=../deps/mio_wrapper/cmake/ios.toolchain.cmake \
      -DPLATFORM=OS64COMBINED \
      -DDEPLOYMENT_TARGET=12.0 \
      -DCMAKE_BUILD_TYPE=Release

cmake --build build/ios --config Release

# Copy results
cp build/ios/Release/libmio_wrapper.a ios/Libraries/
cp ../deps/mio_wrapper/include/mio_wrapper.h ios/Libraries/include/
```

### Podspec Integration

The static library is automatically included via the podspec configuration:

```ruby
s.vendored_libraries = 'Libraries/libmio_wrapper.a'
s.public_header_files = 'Libraries/include/mio_wrapper.h'
```

### Verification

To verify the library contains the correct architectures:

```bash
lipo -info ios/Libraries/libmio_wrapper.a
# Should show: arm64 x86_64 (or similar for universal binary)
```

### Troubleshooting

- Ensure iOS toolchain file is available in mio_wrapper cmake directory
- Verify Xcode command line tools are installed: `xcode-select --install`
- Check iOS SDK availability: `xcodebuild -showsdks`
