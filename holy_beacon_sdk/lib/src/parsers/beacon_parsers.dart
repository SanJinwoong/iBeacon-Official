import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/beacon_models.dart';
import '../models/beacon_profile_manager.dart';

/// Parser for various beacon protocols and formats with dynamic profile support
class BeaconParsers {
  static final BeaconProfileManager _profileManager = BeaconProfileManager();

  /// Initialize parser with profile manager
  static Future<void> initialize() async {
    await _profileManager.initialize();
  }

  /// Registrar un beacon verificado (delegación al profile manager)
  static Future<void> registerVerifiedBeacon(
    String uuid,
    String name, {
    int trustLevel = 5,
    Map<String, dynamic>? metadata,
  }) async {
    await _profileManager.registerVerifiedBeacon(
      uuid,
      name,
      trustLevel: trustLevel,
      metadata: metadata,
    );
  }

  /// Desregistrar un beacon verificado
  static Future<void> unregisterVerifiedBeacon(String uuid) async {
    await _profileManager.unregisterVerifiedBeacon(uuid);
  }

  /// Listar beacons verificados
  static List<BeaconProfile> listVerifiedBeacons() {
    return _profileManager.listVerifiedBeacons();
  }

  /// Limpiar todos los beacons verificados
  static Future<void> clearVerifiedBeacons({bool keepDefaults = false}) async {
    await _profileManager.clearVerifiedBeacons(keepDefaults: keepDefaults);
  }

  /// Limpiar perfiles por defecto
  static Future<void> clearDefaultProfiles() async {
    await _profileManager.clearDefaultProfiles();
  }

  /// Restaurar perfiles por defecto
  static Future<void> restoreDefaultProfiles() async {
    await _profileManager.restoreDefaultProfiles();
  }

  /// Verificar si un UUID está registrado
  static bool isVerifiedBeacon(String uuid) {
    return _profileManager.isVerifiedBeacon(uuid);
  }

  /// Obtener perfil por UUID
  static BeaconProfile? getProfile(String uuid) {
    return _profileManager.getProfile(uuid);
  }

  /// Obtener UUIDs conocidos (compatibilidad)
  static List<String> get knownUuids => _profileManager.getKnownUuids();

  /// Estadísticas de perfiles
  static Map<String, int> getProfileStats() => _profileManager.getStats();

  /// Attempts to parse manufacturer data as iBeacon
  static BeaconDevice? tryParseIBeacon(
    String deviceId,
    String name,
    int rssi,
    Uint8List manufacturerData,
  ) {
    if (manufacturerData.length < 23) return null;

    try {
      final now = DateTime.now();

      // iBeacon format: 0x004C (Apple Company ID) + 0x02 + 0x15 + UUID(16) + Major(2) + Minor(2) + TX Power(1)
      if (manufacturerData.length >= 25) {
        // Verify iBeacon format (Company ID 0x004C)
        if (manufacturerData[0] == 0x4C &&
            manufacturerData[1] == 0x00 &&
            manufacturerData[2] == 0x02 &&
            manufacturerData[3] == 0x15) {
          // Extract UUID (bytes 4-19)
          final uuidBytes = manufacturerData.sublist(4, 20);
          String uuid = _formatUuid(uuidBytes);

          // Extract Major and Minor
          int major = (manufacturerData[20] << 8) | manufacturerData[21];
          int minor = (manufacturerData[22] << 8) | manufacturerData[23];

          // Get profile if registered
          final profile = _profileManager.getProfile(uuid);
          final isVerified = profile?.verified ?? false;
          final deviceName = profile?.displayName.isNotEmpty == true
              ? profile!.displayName
              : (name.isNotEmpty ? name : 'iBeacon');

          return BeaconDevice(
            deviceId: deviceId,
            name: deviceName,
            rssi: rssi,
            uuid: uuid,
            major: major,
            minor: minor,
            protocol: BeaconProtocol.ibeacon,
            lastSeen: now,
            verified: isVerified,
          );
        }
      }
    } catch (e) {
      print('Error parsing iBeacon: $e');
    }

    return null;
  }

  /// Attempts to parse service data as Eddystone
  static BeaconDevice? tryParseEddystone(
    String deviceId,
    String name,
    int rssi,
    Map<Uuid, Uint8List> serviceData,
  ) {
    try {
      final now = DateTime.now();

      // Eddystone uses Service UUID 0xFEAA
      final eddystoneEntry = serviceData.entries.firstWhere(
        (entry) => entry.key.toString().toUpperCase().contains('FEAA'),
        orElse: () => throw StateError('No Eddystone UUID found'),
      );

      final data = eddystoneEntry.value;
      if (data.isEmpty) return null;

      final frameType = data[0];

      switch (frameType) {
        case 0x00: // Eddystone-UID
          return _parseEddystoneUid(deviceId, name, rssi, data, now);
        case 0x10: // Eddystone-URL
          return _parseEddystoneUrl(deviceId, name, rssi, data, now);
        default:
          print(
              'Unknown Eddystone frame type: 0x${frameType.toRadixString(16)}');
          return null;
      }
    } catch (e) {
      print('Error parsing Eddystone: $e');
      return null;
    }
  }

  /// Parse Eddystone-UID frame
  static BeaconDevice? _parseEddystoneUid(
    String deviceId,
    String name,
    int rssi,
    Uint8List data,
    DateTime now,
  ) {
    if (data.length < 18) return null;

    try {
      // Extract Namespace (10 bytes) and Instance (6 bytes)
      final namespace = data.sublist(2, 12);
      final instance = data.sublist(12, 18);

      // Create a pseudo-UUID from namespace and instance
      final uuid = _createUuidFromEddystone(namespace, instance);

      return BeaconDevice(
        deviceId: deviceId,
        name: name.isNotEmpty ? name : 'Eddystone UID',
        rssi: rssi,
        uuid: uuid,
        major: 0,
        minor: 0,
        protocol: BeaconProtocol.eddystoneUid,
        lastSeen: now,
        verified: false,
      );
    } catch (e) {
      print('Error parsing Eddystone UID: $e');
      return null;
    }
  }

  /// Parse Eddystone-URL frame
  static BeaconDevice? _parseEddystoneUrl(
    String deviceId,
    String name,
    int rssi,
    Uint8List data,
    DateTime now,
  ) {
    if (data.length < 4) return null;

    try {
      // Extract URL scheme and encoded URL
      final urlData = data.sublist(2);
      final url = _decodeEddystoneUrl(urlData);

      // Create a UUID based on URL hash
      final uuid = _createUuidFromUrl(url);

      return BeaconDevice(
        deviceId: deviceId,
        name: name.isNotEmpty ? name : 'Eddystone URL',
        rssi: rssi,
        uuid: uuid,
        major: 0,
        minor: 0,
        protocol: BeaconProtocol.eddystoneUrl,
        lastSeen: now,
        verified: false,
      );
    } catch (e) {
      print('Error parsing Eddystone URL: $e');
      return null;
    }
  }

  /// Create generic BLE device when no beacon format is detected
  static BeaconDevice createGenericBleDevice(
    String deviceId,
    String name,
    int rssi,
    Uint8List? manufacturerData,
  ) {
    String uuid = '';

    // Try to extract some identifier from manufacturer data
    if (manufacturerData != null && manufacturerData.length >= 6) {
      uuid = manufacturerData
          .take(16)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toUpperCase();

      // Pad with zeros if too short
      if (uuid.length < 32) {
        uuid = uuid.padRight(32, '0');
      }

      // Limit to 32 characters for UUID formatting
      if (uuid.length > 32) {
        uuid = uuid.substring(0, 32);
      }
    }

    // Check if the name contains registered patterns or is verified
    final profile = _profileManager.getProfile(uuid);
    bool isKnownDevice = profile?.verified ??
        (name.toLowerCase().contains('holy') ||
            name.toLowerCase().contains('kronos') ||
            name.toLowerCase().contains('blaze'));

    return BeaconDevice(
      deviceId: deviceId,
      name: name.isNotEmpty ? name : 'BLE Device',
      rssi: rssi,
      uuid: _insertUuidDashes(uuid),
      major: 0,
      minor: 0,
      protocol: BeaconProtocol.bleDevice,
      lastSeen: DateTime.now(),
      verified: isKnownDevice,
    );
  }

  // Helper methods

  /// Format UUID bytes to standard UUID format
  static String _formatUuid(Uint8List bytes) {
    if (bytes.length < 16) return '';

    String hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return _insertUuidDashes(hex);
  }

  /// Insert dashes into UUID string for proper formatting
  static String _insertUuidDashes(String hex) {
    if (hex.length != 32) return hex;
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Get friendly device name from UUID
  static String _getDeviceNameFromUuid(String uuid) {
    final profile = _profileManager.getProfile(uuid);
    if (profile != null) {
      return profile.displayName;
    }

    // Fallback for unregistered devices
    return 'iBeacon';
  }

  /// Create UUID from Eddystone namespace and instance
  static String _createUuidFromEddystone(
      Uint8List namespace, Uint8List instance) {
    final combined = Uint8List.fromList([...namespace, ...instance]);
    final hex = combined
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return _insertUuidDashes(hex.padRight(32, '0'));
  }

  /// Create UUID from URL hash
  static String _createUuidFromUrl(String url) {
    final bytes = url.codeUnits.take(16).toList();
    while (bytes.length < 16) bytes.add(0);
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return _insertUuidDashes(hex);
  }

  /// Decode Eddystone URL from encoded data
  static String _decodeEddystoneUrl(Uint8List data) {
    if (data.isEmpty) return '';

    const schemes = [
      'http://www.',
      'https://www.',
      'http://',
      'https://',
    ];

    final scheme = data[0] < schemes.length ? schemes[data[0]] : '';
    final urlData = data.sublist(1);

    final StringBuffer url = StringBuffer(scheme);

    for (final byte in urlData) {
      if (byte == 0) break;
      url.writeCharCode(byte);
    }

    return url.toString();
  }

  /// Check if a device ID represents a registered device
  static bool isHolyDevice(String deviceId, String name) {
    // Check by name patterns (legacy compatibility)
    final nameLower = name.toLowerCase();
    if (nameLower.contains('holy') ||
        nameLower.contains('kronos') ||
        nameLower.contains('blaze')) {
      return true;
    }

    // Check if device ID matches any registered UUIDs
    return _profileManager.getKnownUuids().any((uuid) =>
        deviceId.toLowerCase().contains(uuid.toLowerCase()) ||
        uuid.toLowerCase().contains(deviceId.toLowerCase()));
  }

  /// Validate UUID format
  static bool isValidUuid(String uuid) {
    final pattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return pattern.hasMatch(uuid);
  }
}
