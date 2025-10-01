import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/beacon_models.dart';

/// Parser for various beacon protocols and formats
class BeaconParsers {
  // Known UUIDs for Holy devices
  static const String HOLY_SHUN_UUID = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';
  static const String HOLY_JIN_UUID = 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000';
  static const String KRONOS_BLAZE_UUID =
      'F7826DA6-4FA2-4E98-8024-BC5B71E0893E';

  static const List<String> KNOWN_UUIDS = [
    HOLY_SHUN_UUID,
    HOLY_JIN_UUID,
    KRONOS_BLAZE_UUID,
  ];

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

          // Extract TX Power (signed byte) - stored for future use
          // int txPower = manufacturerData.length > 24
          //     ? manufacturerData[24].toSigned(8)
          //     : -59;

          return BeaconDevice(
            deviceId: deviceId,
            name: name.isNotEmpty ? name : _getDeviceNameFromUuid(uuid),
            rssi: rssi,
            uuid: uuid,
            major: major,
            minor: minor,
            protocol: BeaconProtocol.ibeacon,
            lastSeen: now,
            verified: true,
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

    // Check if the name contains "Holy" or other known patterns
    bool isKnownDevice = name.toLowerCase().contains('holy') ||
        name.toLowerCase().contains('kronos') ||
        name.toLowerCase().contains('blaze');

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
    switch (uuid.toUpperCase()) {
      case HOLY_SHUN_UUID:
        return 'Holy-Shun';
      case HOLY_JIN_UUID:
        return 'Holy-IOT Jin';
      case KRONOS_BLAZE_UUID:
        return 'Kronos Blaze BLE';
      default:
        return 'iBeacon';
    }
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

  /// Check if a device ID represents a Holy device
  static bool isHolyDevice(String deviceId, String name) {
    return name.toLowerCase().contains('holy') ||
        name.toLowerCase().contains('kronos') ||
        name.toLowerCase().contains('blaze');
  }

  /// Validate UUID format
  static bool isValidUuid(String uuid) {
    final pattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return pattern.hasMatch(uuid);
  }
}
