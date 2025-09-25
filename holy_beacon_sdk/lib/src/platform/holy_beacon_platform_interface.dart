import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/beacon_models.dart';

/// Platform interface for Holy Beacon SDK native implementations
abstract class HolyBeaconPlatformInterface {
  static HolyBeaconPlatformInterface? _instance;

  /// The default instance of [HolyBeaconPlatformInterface] to use.
  static HolyBeaconPlatformInterface get instance {
    return _instance ??= MethodChannelHolyBeacon();
  }

  /// Platform-specific initialization
  Future<void> initialize();

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled();

  /// Request Bluetooth to be enabled
  Future<bool> requestBluetoothEnable();

  /// Start native beacon scanning
  Future<void> startNativeScan();

  /// Stop native beacon scanning
  Future<void> stopNativeScan();

  /// Get discovered devices from native implementation
  Stream<BeaconDevice> get deviceStream;

  /// Set scanning parameters
  Future<void> setScanParameters({
    Duration? scanDuration,
    int? scanMode,
  });
}

/// Method channel implementation of the platform interface
class MethodChannelHolyBeacon extends HolyBeaconPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('holy_beacon_sdk');

  /// The event channel for receiving beacon data
  @visibleForTesting
  final eventChannel = const EventChannel('holy_beacon_sdk/events');

  late Stream<BeaconDevice> _deviceStream;

  MethodChannelHolyBeacon() {
    _deviceStream = eventChannel.receiveBroadcastStream().map((data) {
      return BeaconDevice.fromJson(Map<String, dynamic>.from(data));
    });
  }

  @override
  Future<void> initialize() async {
    try {
      await methodChannel.invokeMethod('initialize');
    } on PlatformException catch (e) {
      throw HolyBeaconPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to initialize',
        details: e.details,
      );
    }
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      final result =
          await methodChannel.invokeMethod<bool>('isBluetoothEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      throw HolyBeaconPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to check Bluetooth status',
        details: e.details,
      );
    }
  }

  @override
  Future<bool> requestBluetoothEnable() async {
    try {
      final result =
          await methodChannel.invokeMethod<bool>('requestBluetoothEnable');
      return result ?? false;
    } on PlatformException catch (e) {
      throw HolyBeaconPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to request Bluetooth enable',
        details: e.details,
      );
    }
  }

  @override
  Future<void> startNativeScan() async {
    try {
      await methodChannel.invokeMethod('startScan');
    } on PlatformException catch (e) {
      throw HolyBeaconPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to start native scan',
        details: e.details,
      );
    }
  }

  @override
  Future<void> stopNativeScan() async {
    try {
      await methodChannel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      throw HolyBeaconPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to stop native scan',
        details: e.details,
      );
    }
  }

  @override
  Stream<BeaconDevice> get deviceStream => _deviceStream;

  @override
  Future<void> setScanParameters({
    Duration? scanDuration,
    int? scanMode,
  }) async {
    try {
      final parameters = <String, dynamic>{};

      if (scanDuration != null) {
        parameters['scanDuration'] = scanDuration.inMilliseconds;
      }

      if (scanMode != null) {
        parameters['scanMode'] = scanMode;
      }

      await methodChannel.invokeMethod('setScanParameters', parameters);
    } on PlatformException catch (e) {
      throw HolyBeaconPlatformException(
        code: e.code,
        message: e.message ?? 'Failed to set scan parameters',
        details: e.details,
      );
    }
  }
}

/// Exception thrown by platform implementations
class HolyBeaconPlatformException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  const HolyBeaconPlatformException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    return 'HolyBeaconPlatformException(code: $code, message: $message, details: $details)';
  }
}

/// Scan modes for different platforms
class ScanMode {
  static const int opportunistic = 0; // Android: SCAN_MODE_OPPORTUNISTIC
  static const int lowPower = 1; // Android: SCAN_MODE_LOW_POWER
  static const int balanced = 2; // Android: SCAN_MODE_BALANCED
  static const int lowLatency = 3; // Android: SCAN_MODE_LOW_LATENCY
}
