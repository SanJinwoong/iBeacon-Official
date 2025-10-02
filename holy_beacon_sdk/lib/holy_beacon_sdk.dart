/// Holy Beacon SDK - A comprehensive Flutter library for beacon scanning
///
/// This library provides easy-to-use APIs for:
/// - iBeacon detection and scanning
/// - Eddystone beacon support
/// - Holy devices prioritization
/// - Cross-platform BLE scanning
/// - Permission management
/// - UUID processing and validation
/// - Integration-ready for larger systems
///
/// Example usage:
/// ```dart
/// import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';
///
/// // UUID Processing
/// final result = UuidProcessor.processSingleUuid('FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
/// print('Is Holy device: ${result.isHolyDevice}');
///
/// // Beacon Scanning
/// final scanner = HolyBeaconScanner();
/// scanner.devices.listen((devices) {
///   for (final device in devices) {
///     print('Found: ${device.name} - ${device.uuid}');
///   }
/// });
/// await scanner.startScanning();
/// ```

library holy_beacon_sdk;

// Core UUID processing - the heart of the SDK
export 'src/core/uuid_processor.dart';

// Core models
export 'src/models/beacon_models.dart';
export 'src/models/beacon_whitelist.dart';

// Profile management
export 'src/models/beacon_profile_manager.dart';

// Parsers
export 'src/parsers/beacon_parsers.dart';

// Core service
export 'src/services/holy_beacon_scanner.dart';

// Utils
export 'src/utils/beacon_utils.dart';
export 'src/utils/permission_manager.dart';

// Platform interfaces
export 'src/platform/holy_beacon_platform_interface.dart';
