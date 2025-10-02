import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/beacon_models.dart';
import '../models/beacon_whitelist.dart';
import '../models/beacon_profile_manager.dart';
import '../parsers/beacon_parsers.dart';
import '../utils/permission_manager.dart';

/// Main service class for Holy Beacon SDK
///
/// This class provides comprehensive beacon scanning functionality with:
/// - Cross-platform BLE scanning
/// - Dynamic beacon profile registration
/// - Permission management
/// - Configurable filtering
/// - Real-time device updates
/// - Persistent profile management
///
/// Example usage:
/// ```dart
/// final scanner = HolyBeaconScanner();
///
/// // Register custom beacons
/// await scanner.registerVerifiedBeacon(
///   'A0B1C2D3-0000-1111-2222-333344445555',
///   'My Enterprise Beacon',
///   trustLevel: 8,
/// );
///
/// // Listen for detected devices
/// scanner.onBeaconDetected((device) {
///   print('Found: ${device.name} - verified: ${device.verified}');
/// });
///
/// await scanner.startScanning();
/// ```
class HolyBeaconScanner {
  static final HolyBeaconScanner _instance = HolyBeaconScanner._internal();
  factory HolyBeaconScanner() => _instance;
  HolyBeaconScanner._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  Timer? _autoStopTimer;

  final _devicesController = StreamController<List<BeaconDevice>>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _errorController = StreamController<HolyBeaconError>.broadcast();
  final _beaconDetectedController = StreamController<BeaconDevice>.broadcast();

  final _devices = <String, BeaconDevice>{};
  BeaconWhitelist _whitelist = const BeaconWhitelist();
  BeaconScanConfig _config = const BeaconScanConfig();

  /// Stream of discovered beacon devices
  Stream<List<BeaconDevice>> get devices => _devicesController.stream;

  /// Stream of scanner status messages
  Stream<String> get status => _statusController.stream;

  /// Stream of scanner errors
  Stream<HolyBeaconError> get errors => _errorController.stream;

  /// Stream of individual beacon detections
  Stream<BeaconDevice> get beaconDetected => _beaconDetectedController.stream;

  /// Whether the scanner is currently active
  bool get isScanning => _scanSubscription != null;

  /// Current device whitelist configuration
  BeaconWhitelist get whitelist => _whitelist;

  /// Current scan configuration
  BeaconScanConfig get config => _config;

  /// Initialize the scanner with configuration
  Future<void> initialize({
    BeaconWhitelist? whitelist,
    BeaconScanConfig? config,
  }) async {
    await BeaconParsers.initialize(); // Initialize profile manager
    _whitelist = whitelist ?? const BeaconWhitelist();
    _config = config ?? const BeaconScanConfig();

    if (_config.enableDebugLogs) {
      print('🔧 HolyBeaconScanner initialized');
      print('🔧 Whitelist: $_whitelist');
      print('🔧 Config: $_config');
      print('🔧 Profiles loaded: ${BeaconParsers.getProfileStats()}');
    }
  }

  // ========== NUEVAS APIs REQUERIDAS ==========

  /// Register a verified beacon with custom metadata
  Future<void> registerVerifiedBeacon(
    String uuid,
    String name, {
    int trustLevel = 5,
    Map<String, dynamic>? metadata,
  }) async {
    await BeaconParsers.registerVerifiedBeacon(
      uuid,
      name,
      trustLevel: trustLevel,
      metadata: metadata,
    );

    if (_config.enableDebugLogs) {
      print('✅ Registered beacon: $name ($uuid) - trust: $trustLevel');
    }
  }

  /// Unregister a verified beacon
  Future<void> unregisterVerifiedBeacon(String uuid) async {
    await BeaconParsers.unregisterVerifiedBeacon(uuid);

    if (_config.enableDebugLogs) {
      print('❌ Unregistered beacon: $uuid');
    }
  }

  /// List all verified beacons
  List<BeaconProfile> listVerifiedBeacons() {
    return BeaconParsers.listVerifiedBeacons();
  }

  /// Clear all verified beacons (optionally keep defaults)
  Future<void> clearVerifiedBeacons({bool keepDefaults = false}) async {
    await BeaconParsers.clearVerifiedBeacons(keepDefaults: keepDefaults);

    if (_config.enableDebugLogs) {
      print('🧹 Cleared verified beacons (keepDefaults: $keepDefaults)');
    }
  }

  /// Clear/disable default profiles (Holy devices)
  Future<void> clearDefaultProfiles() async {
    await BeaconParsers.clearDefaultProfiles();

    if (_config.enableDebugLogs) {
      print('🧹 Cleared default profiles');
    }
  }

  /// Restore default profiles (Holy devices)
  Future<void> restoreDefaultProfiles() async {
    await BeaconParsers.restoreDefaultProfiles();

    if (_config.enableDebugLogs) {
      print('🔄 Restored default profiles');
    }
  }

  /// Register callback for individual beacon detections
  void onBeaconDetected(void Function(BeaconDevice) callback) {
    beaconDetected.listen(callback);
  }

  /// Get statistics about registered profiles
  Map<String, int> getProfileStats() {
    return BeaconParsers.getProfileStats();
  }

  // ========== MÉTODOS EXISTENTES MEJORADOS ==========

  /// Request necessary permissions for beacon scanning
  Future<bool> requestPermissions() async {
    final permissionManager = PermissionManager();
    final hasPermissions = await permissionManager.requestBeaconPermissions();

    if (!hasPermissions) {
      _errorController.add(HolyBeaconError(
        code: 'PERMISSIONS_DENIED',
        message: 'Required permissions not granted for beacon scanning',
        type: HolyBeaconErrorType.permissions,
      ));
    }

    return hasPermissions;
  }

  /// Start scanning for beacon devices
  Future<void> startScanning({
    BeaconScanConfig? config,
  }) async {
    if (isScanning) await stopScanning();

    _config = config ?? _config;

    try {
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        _statusController.add('⚠️ Insufficient permissions for scanning');
        return;
      }

      _devices.clear();
      _emitDevices();
      _statusController.add('🔍 Starting BLE scan...');

      // Configure scan settings for maximum detection
      _scanSubscription = _ble.scanForDevices(
        withServices: [],
        scanMode: ScanMode.lowLatency, // Most aggressive scanning
        requireLocationServicesEnabled: false,
      ).listen(
        _onDeviceDiscovered,
        onError: (e) {
          _handleError('SCAN_ERROR', 'BLE scan error: $e');
        },
      );

      // Set up auto-stop timer if configured
      if (_config.scanDuration != null) {
        _autoStopTimer = Timer(_config.scanDuration!, () {
          stopScanning();
          _statusController.add('⏰ Scan completed (timeout)');
        });
      }

      _statusController.add('✅ Scanning started');
    } catch (e) {
      _handleError('START_SCAN_FAILED', 'Failed to start scanning: $e');
    }
  }

  /// Stop the current scanning operation
  Future<void> stopScanning() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      _statusController.add('⏹️ Scanning stopped');
      if (_config.enableDebugLogs) {
        print('⏹️ Scanner stopped');
      }
    } catch (e) {
      _handleError('STOP_SCAN_FAILED', 'Error stopping scan: $e');
    }
  }

  /// Process discovered BLE device
  void _onDeviceDiscovered(DiscoveredDevice device) {
    final detectedBeacons = <BeaconDevice>[];

    // Try to parse as iBeacon from manufacturer data
    if (device.manufacturerData.isNotEmpty) {
      final beacon = BeaconParsers.tryParseIBeacon(
        device.id,
        device.name,
        device.rssi,
        device.manufacturerData,
      );
      if (beacon != null) {
        detectedBeacons.add(beacon);

        // Emit device individually for callback listeners
        _beaconDetectedController.add(beacon);

        if (_config.enableDebugLogs) {
          print('📱 iBeacon detected: ${beacon.name} (${beacon.uuid})');
          if (beacon.verified) {
            print('⭐ Verified beacon: ${beacon.name}');
          }
        }
      }
    }

    // Try to parse as Eddystone from service data
    if (device.serviceData.isNotEmpty) {
      final eddystoneBeacon = BeaconParsers.tryParseEddystone(
        device.id,
        device.name,
        device.rssi,
        device.serviceData,
      );
      if (eddystoneBeacon != null) {
        detectedBeacons.add(eddystoneBeacon);

        // Emit device individually for callback listeners
        _beaconDetectedController.add(eddystoneBeacon);

        if (_config.enableDebugLogs) {
          print('🟦 Eddystone detected: ${eddystoneBeacon.name}');
          if (eddystoneBeacon.verified) {
            print('⭐ Verified Eddystone: ${eddystoneBeacon.name}');
          }
        }
      }
    }

    // If no beacon protocol detected but device has a name or is Holy, create generic BLE device
    if (detectedBeacons.isEmpty &&
        (device.name.isNotEmpty || _isHolyDevice(device))) {
      final genericDevice = BeaconParsers.createGenericBleDevice(
        device.id,
        device.name,
        device.rssi,
        device.manufacturerData,
      );
      detectedBeacons.add(genericDevice);

      // Emit device individually for callback listeners
      _beaconDetectedController.add(genericDevice);

      if (_config.enableDebugLogs) {
        print('📶 Generic BLE detected: ${genericDevice.name}');
      }
    }

    // Process all detected beacons
    for (final beacon in detectedBeacons) {
      _processBeaconDevice(beacon);
    }
  }

  /// Process and add beacon device to the collection
  void _processBeaconDevice(BeaconDevice beacon) {
    // Apply RSSI filter
    if (_config.minRssi != null && beacon.rssi < _config.minRssi!) {
      return;
    }

    // Apply whitelist filter
    if (!_whitelist.isAllowed(beacon)) {
      if (_config.enableDebugLogs) {
        print('🚫 Device filtered out: ${beacon.name}');
      }
      return;
    }

    final existingDevice = _devices[beacon.deviceId];
    if (existingDevice != null) {
      // Update existing device
      _devices[beacon.deviceId] = existingDevice.updateSeen(rssi: beacon.rssi);
    } else {
      // Add new device
      _devices[beacon.deviceId] = beacon;

      if (_config.enableDebugLogs) {
        print('✅ New device added: ${beacon.name} (${beacon.deviceId})');
      }
    }

    _emitDevices();
  }

  /// Check if device is a Holy device based on various criteria
  bool _isHolyDevice(DiscoveredDevice device) {
    return device.name.toLowerCase().contains('holy') ||
        device.name.toLowerCase().contains('kronos') ||
        device.name.toLowerCase().contains('blaze');
  }

  /// Emit sorted devices list
  void _emitDevices() {
    var sortedDevices = _devices.values.toList();

    // Sort devices with Holy devices first if configured
    if (_config.prioritizeHolyDevices) {
      sortedDevices.sort((a, b) {
        if (a.isHolyDevice && !b.isHolyDevice) return -1;
        if (!a.isHolyDevice && b.isHolyDevice) return 1;
        return b.rssi
            .compareTo(a.rssi); // Secondary sort by RSSI (stronger first)
      });
    } else {
      // Sort by RSSI only
      sortedDevices.sort((a, b) => b.rssi.compareTo(a.rssi));
    }

    _devicesController.add(sortedDevices);

    // Update status with device count
    final totalDevices = sortedDevices.length;
    final holyDevices = sortedDevices.where((d) => d.isHolyDevice).length;
    final verifiedDevices = sortedDevices.where((d) => d.verified).length;

    if (isScanning) {
      _statusController.add(
        '🔍 Scanning: $totalDevices devices '
        '(Holy: $holyDevices, Verified: $verifiedDevices)',
      );
    }
  }

  /// Handle scanner errors
  void _handleError(String code, String message) {
    final error = HolyBeaconError(
      code: code,
      message: message,
      type: _getErrorType(code),
    );

    _errorController.add(error);
    _statusController.add('❌ Error: $message');

    if (_config.enableDebugLogs) {
      print('❌ $code: $message');
    }
  }

  /// Get error type from error code
  HolyBeaconErrorType _getErrorType(String code) {
    switch (code) {
      case 'PERMISSIONS_DENIED':
        return HolyBeaconErrorType.permissions;
      case 'BLUETOOTH_DISABLED':
        return HolyBeaconErrorType.bluetooth;
      case 'SCAN_ERROR':
      case 'START_SCAN_FAILED':
      case 'STOP_SCAN_FAILED':
        return HolyBeaconErrorType.scanning;
      default:
        return HolyBeaconErrorType.unknown;
    }
  }

  /// Update whitelist configuration
  void setWhitelist(BeaconWhitelist whitelist) {
    _whitelist = whitelist;
    if (_config.enableDebugLogs) {
      print('🔧 Whitelist updated: $_whitelist');
    }
  }

  /// Clear all discovered devices
  void clearDevices() {
    _devices.clear();
    _emitDevices();
  }

  /// Get current device statistics
  BeaconScanStats getStats() {
    final devices = _devices.values.toList();
    return BeaconScanStats(
      totalDevices: devices.length,
      holyDevices: devices.where((d) => d.isHolyDevice).length,
      verifiedDevices: devices.where((d) => d.verified).length,
      ibeaconDevices:
          devices.where((d) => d.protocol == BeaconProtocol.ibeacon).length,
      eddystoneDevices: devices
          .where((d) =>
              d.protocol == BeaconProtocol.eddystoneUid ||
              d.protocol == BeaconProtocol.eddystoneUrl)
          .length,
      bleDevices:
          devices.where((d) => d.protocol == BeaconProtocol.bleDevice).length,
      averageRssi: devices.isEmpty
          ? 0
          : devices.map((d) => d.rssi).reduce((a, b) => a + b) / devices.length,
      strongestRssi: devices.isEmpty
          ? 0
          : devices.map((d) => d.rssi).reduce((a, b) => a > b ? a : b),
      weakestRssi: devices.isEmpty
          ? 0
          : devices.map((d) => d.rssi).reduce((a, b) => a < b ? a : b),
    );
  }

  /// Get devices by protocol type
  List<BeaconDevice> getDevicesByProtocol(BeaconProtocol protocol) {
    return _devices.values.where((d) => d.protocol == protocol).toList();
  }

  /// Get Holy devices only
  List<BeaconDevice> getHolyDevices() {
    return _devices.values.where((d) => d.isHolyDevice).toList();
  }

  /// Dispose of resources
  void dispose() {
    stopScanning();
    _devicesController.close();
    _statusController.close();
    _errorController.close();
    _beaconDetectedController.close();
  }
}

/// Scan statistics
class BeaconScanStats {
  final int totalDevices;
  final int holyDevices;
  final int verifiedDevices;
  final int ibeaconDevices;
  final int eddystoneDevices;
  final int bleDevices;
  final double averageRssi;
  final int strongestRssi;
  final int weakestRssi;

  const BeaconScanStats({
    required this.totalDevices,
    required this.holyDevices,
    required this.verifiedDevices,
    required this.ibeaconDevices,
    required this.eddystoneDevices,
    required this.bleDevices,
    required this.averageRssi,
    required this.strongestRssi,
    required this.weakestRssi,
  });

  @override
  String toString() {
    return 'BeaconScanStats(total: $totalDevices, holy: $holyDevices, verified: $verifiedDevices, iBeacon: $ibeaconDevices, Eddystone: $eddystoneDevices, BLE: $bleDevices)';
  }
}

/// Error types for beacon scanning
enum HolyBeaconErrorType {
  permissions,
  bluetooth,
  scanning,
  unknown,
}

/// Error class for beacon scanning operations
class HolyBeaconError {
  final String code;
  final String message;
  final HolyBeaconErrorType type;
  final DateTime timestamp;

  HolyBeaconError({
    required this.code,
    required this.message,
    required this.type,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'HolyBeaconError(code: $code, message: $message, type: $type)';
  }
}
