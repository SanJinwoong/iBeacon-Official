import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// Manages permissions required for beacon scanning across platforms
class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  /// Request all permissions required for beacon scanning
  Future<bool> requestBeaconPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await _requestAndroidPermissions();
      } else if (Platform.isIOS) {
        return await _requestIosPermissions();
      }

      // For other platforms, assume permissions are not required
      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Request Android-specific permissions
  Future<bool> _requestAndroidPermissions() async {
    final permissions = <Permission>[];

    // Location permissions (required for BLE scanning on Android 6+)
    permissions.add(Permission.location);
    permissions.add(Permission.locationWhenInUse);

    // Bluetooth permissions for Android 12+ (API 31+)
    if (await _isAndroid12OrHigher()) {
      permissions.addAll([
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ]);
    } else {
      // Legacy Bluetooth permissions for Android 11 and below
      permissions.addAll([
        Permission.bluetooth,
        // Note: BLUETOOTH_ADMIN is not available in permission_handler
        // It's declared in AndroidManifest.xml
      ]);
    }

    // Request all permissions
    final statuses = await permissions.request();

    // Check if all critical permissions are granted
    final criticalPermissions = [
      Permission.location,
      if (await _isAndroid12OrHigher()) ...[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ] else ...[
        Permission.bluetooth,
      ],
    ];

    final allCriticalGranted = criticalPermissions.every(
      (permission) => statuses[permission] == PermissionStatus.granted,
    );

    if (!allCriticalGranted) {
      print('❌ Critical permissions not granted:');
      for (final permission in criticalPermissions) {
        final status = statuses[permission];
        if (status != PermissionStatus.granted) {
          print('  - $permission: $status');
        }
      }
    }

    return allCriticalGranted;
  }

  /// Request iOS-specific permissions
  Future<bool> _requestIosPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.locationWhenInUse,
    ];

    final statuses = await permissions.request();

    final allGranted = statuses.values.every(
      (status) =>
          status == PermissionStatus.granted ||
          status == PermissionStatus.limited,
    );

    if (!allGranted) {
      print('❌ iOS permissions not granted:');
      for (final entry in statuses.entries) {
        if (entry.value != PermissionStatus.granted &&
            entry.value != PermissionStatus.limited) {
          print('  - ${entry.key}: ${entry.value}');
        }
      }
    }

    return allGranted;
  }

  /// Check current permission status
  Future<PermissionStatusSummary> checkPermissionStatus() async {
    try {
      if (Platform.isAndroid) {
        return await _checkAndroidPermissionStatus();
      } else if (Platform.isIOS) {
        return await _checkIosPermissionStatus();
      }

      return const PermissionStatusSummary(
        allGranted: true,
        bluetoothGranted: true,
        locationGranted: true,
        details: {
          'platform': 'Unsupported platform - assuming permissions granted'
        },
      );
    } catch (e) {
      print('Error checking permission status: $e');
      return PermissionStatusSummary(
        allGranted: false,
        bluetoothGranted: false,
        locationGranted: false,
        details: {'error': e.toString()},
      );
    }
  }

  /// Check Android permission status
  Future<PermissionStatusSummary> _checkAndroidPermissionStatus() async {
    final statuses = <String, PermissionStatus>{};

    // Check location permission
    final locationStatus = await Permission.location.status;
    statuses['location'] = locationStatus;

    // Check Bluetooth permissions based on Android version
    if (await _isAndroid12OrHigher()) {
      statuses['bluetoothScan'] = await Permission.bluetoothScan.status;
      statuses['bluetoothConnect'] = await Permission.bluetoothConnect.status;
      statuses['bluetoothAdvertise'] =
          await Permission.bluetoothAdvertise.status;
    } else {
      statuses['bluetooth'] = await Permission.bluetooth.status;
    }

    final locationGranted = locationStatus == PermissionStatus.granted;
    final bluetoothGranted = await _isAndroid12OrHigher()
        ? (statuses['bluetoothScan'] == PermissionStatus.granted &&
            statuses['bluetoothConnect'] == PermissionStatus.granted)
        : statuses['bluetooth'] == PermissionStatus.granted;

    return PermissionStatusSummary(
      allGranted: locationGranted && bluetoothGranted,
      bluetoothGranted: bluetoothGranted,
      locationGranted: locationGranted,
      details: statuses.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  /// Check iOS permission status
  Future<PermissionStatusSummary> _checkIosPermissionStatus() async {
    final bluetoothStatus = await Permission.bluetooth.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    final bluetoothGranted = bluetoothStatus == PermissionStatus.granted ||
        bluetoothStatus == PermissionStatus.limited;
    final locationGranted = locationStatus == PermissionStatus.granted ||
        locationStatus == PermissionStatus.limited;

    return PermissionStatusSummary(
      allGranted: bluetoothGranted && locationGranted,
      bluetoothGranted: bluetoothGranted,
      locationGranted: locationGranted,
      details: {
        'bluetooth': bluetoothStatus.toString(),
        'location': locationStatus.toString(),
      },
    );
  }

  /// Check if device is running Android 12 or higher
  Future<bool> _isAndroid12OrHigher() async {
    if (!Platform.isAndroid) return false;

    try {
      // This is a simplified check - in a real implementation, you might want
      // to use device_info_plus to get the actual Android API level
      return true; // For now, assume modern Android
    } catch (e) {
      return false;
    }
  }

  /// Show permission rationale to user
  Future<void> showPermissionRationale(String message) async {
    print('📱 Permission Rationale: $message');
    // In a real app, you would show a dialog or similar UI
  }

  /// Open app settings for manual permission configuration
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
      return false;
    }
  }

  /// Check if location services are enabled (Android)
  Future<bool> isLocationServiceEnabled() async {
    if (!Platform.isAndroid) return true;

    try {
      return await Permission.location.serviceStatus == ServiceStatus.enabled;
    } catch (e) {
      print('Error checking location service status: $e');
      return false;
    }
  }

  /// Request location service to be enabled
  Future<bool> requestLocationService() async {
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.location.serviceStatus;
      if (status == ServiceStatus.disabled) {
        // In a real app, you would guide the user to enable location services
        print(
            '📱 Location services are disabled. Please enable them in device settings.');
        return false;
      }
      return true;
    } catch (e) {
      print('Error requesting location service: $e');
      return false;
    }
  }
}

/// Summary of permission status across the app
class PermissionStatusSummary {
  final bool allGranted;
  final bool bluetoothGranted;
  final bool locationGranted;
  final Map<String, String> details;

  const PermissionStatusSummary({
    required this.allGranted,
    required this.bluetoothGranted,
    required this.locationGranted,
    required this.details,
  });

  /// Get missing permissions list
  List<String> get missingPermissions {
    final missing = <String>[];

    if (!bluetoothGranted) {
      missing.add('Bluetooth');
    }

    if (!locationGranted) {
      missing.add('Location');
    }

    return missing;
  }

  /// Get user-friendly message about permission status
  String get statusMessage {
    if (allGranted) {
      return 'All required permissions are granted';
    }

    final missing = missingPermissions.join(', ');
    return 'Missing permissions: $missing';
  }

  @override
  String toString() {
    return 'PermissionStatusSummary(allGranted: $allGranted, bluetooth: $bluetoothGranted, location: $locationGranted)';
  }
}
