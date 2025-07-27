#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mmap2_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mmap2_flutter'
  s.version          = '0.0.1'
  s.summary          = 'Flutter plugin for memory-mapped file I/O.'
  s.description      = <<-DESC
Flutter plugin for memory-mapped file I/O using the mio C++ library.
Provides cross-platform support for efficient file memory mapping.
                       DESC
  s.homepage         = 'https://github.com/arcticfox1919/mmap-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'arcticfox1919' => 'arcticfox1919@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  
  # Include static library for mio wrapper
  s.vendored_libraries = 'Libraries/libmio_wrapper.a'
  s.public_header_files = 'Libraries/include/mio_wrapper.h'
  s.source_files = ['Classes/**/*', 'Libraries/include/**/*.h']

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'mmap2_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
