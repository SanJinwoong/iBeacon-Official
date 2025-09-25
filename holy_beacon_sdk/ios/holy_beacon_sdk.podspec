#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint holy_beacon_sdk.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'holy_beacon_sdk'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter SDK for scanning and detecting iBeacon and Eddystone beacons with Holy devices prioritization.'
  s.description      = <<-DESC
Holy Beacon SDK provides comprehensive beacon scanning functionality including:
- iBeacon detection and scanning
- Eddystone beacon support  
- Holy devices prioritization
- Cross-platform BLE scanning
- Permission management
                       DESC
  s.homepage         = 'https://github.com/SanJinwoong/holy-beacon-sdk'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'SanJinwoong' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # Privacy manifest for iOS 17+
  s.resource_bundles = {
    'holy_beacon_sdk_privacy' => ['Resources/PrivacyInfo.xcprivacy']
  }
end