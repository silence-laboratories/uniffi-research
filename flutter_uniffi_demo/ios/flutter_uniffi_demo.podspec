#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_uniffi_demo.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_uniffi_demo'
  s.version          = '0.0.1'
  s.summary          = 'A Flutter plugin demonstrating UniFFI callbacks.'
  s.description      = <<-DESC
A Flutter plugin that demonstrates bidirectional communication between Flutter and Rust using UniFFI callbacks.
                       DESC
  s.homepage         = 'https://github.com/your-repo/flutter_uniffi_demo'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Include our native library - use different libraries for simulator vs device
  s.ios.vendored_libraries = 'Frameworks/libuniffi_callback_demo_device.dylib'
  s.ios.sim.vendored_libraries = 'Frameworks/libuniffi_callback_demo_simulator.dylib'
  s.library = 'c++'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'OTHER_LDFLAGS' => '-lc++'
  }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'flutter_uniffi_demo_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
