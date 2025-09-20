import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/beacon_models.dart';

class BeaconParsers {
  // UUIDs conocidos de dispositivos exitosos
  static const String HOLY_SHUN_UUID = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';
  static const String HOLY_JIN_UUID = 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000';
  static const String KRONOS_BLAZE_UUID =
      'F7826DA6-4FA2-4E98-8024-BC5B71E0893E';

  static const List<String> KNOWN_UUIDS = [
    HOLY_SHUN_UUID,
    HOLY_JIN_UUID,
    KRONOS_BLAZE_UUID,
  ];

  /// Intenta parsear como iBeacon
  static BeaconDevice? tryParseIBeacon(
    String deviceId,
    String name,
    int rssi,
    Uint8List manufacturerData,
  ) {
    if (manufacturerData.length < 23) return null;

    try {
      final now = DateTime.now();

      // iBeacon formato: 0x004C (Apple Company ID) + 0x02 + 0x15 + UUID(16) + Major(2) + Minor(2) + TX Power(1)
      if (manufacturerData.length >= 25) {
        // Verificar si es iBeacon (Company ID 0x004C)
        if (manufacturerData[0] == 0x4C &&
            manufacturerData[1] == 0x00 &&
            manufacturerData[2] == 0x02 &&
            manufacturerData[3] == 0x15) {
          // Extraer UUID (bytes 4-19)
          final uuidBytes = manufacturerData.sublist(4, 20);
          String uuid = _formatUuid(uuidBytes);

          // Extraer Major y Minor
          int major = (manufacturerData[20] << 8) | manufacturerData[21];
          int minor = (manufacturerData[22] << 8) | manufacturerData[23];

          bool isVerified = KNOWN_UUIDS.contains(uuid.toUpperCase());

          return BeaconDevice(
            deviceId: deviceId,
            name: name.isNotEmpty ? name : 'iBeacon',
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

      // Formato alternativo: UUID directo al inicio
      if (manufacturerData.length >= 16) {
        final uuidBytes = manufacturerData.sublist(0, 16);
        String uuid = _formatUuid(uuidBytes);

        if (KNOWN_UUIDS.contains(uuid.toUpperCase())) {
          int major = manufacturerData.length > 17
              ? (manufacturerData[16] << 8) | manufacturerData[17]
              : 0;
          int minor = manufacturerData.length > 19
              ? (manufacturerData[18] << 8) | manufacturerData[19]
              : 0;

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

  /// Intenta parsear como Eddystone
  static BeaconDevice? tryParseEddystone(
    String deviceId,
    String name,
    int rssi,
    Map<Uuid, Uint8List> serviceData,
  ) {
    try {
      final now = DateTime.now();

      // Eddystone usa Service UUID 0xFEAA
      final eddystoneUuid = serviceData.keys.firstWhere(
        (uuid) => uuid.toString().toUpperCase().contains('FEAA'),
        orElse: () => throw StateError('No Eddystone UUID found'),
      );

      final eddystoneData = serviceData[eddystoneUuid];
      if (eddystoneData != null && eddystoneData.length > 0) {
        final frameType = eddystoneData[0];

        switch (frameType) {
          case 0x00: // Eddystone-UID
            if (eddystoneData.length >= 18) {
              final namespaceId = eddystoneData.sublist(2, 12);
              final instanceId = eddystoneData.sublist(12, 18);
              final combinedBytes = Uint8List(16);
              combinedBytes.setRange(0, 10, namespaceId);
              combinedBytes.setRange(10, 16, instanceId);
              String uuid = _formatUuid(combinedBytes);

              return BeaconDevice(
                deviceId: deviceId,
                name: name.isNotEmpty ? name : 'Eddystone-UID',
                rssi: rssi,
                uuid: uuid,
                major: 0,
                minor: 0,
                protocol: BeaconProtocol.eddystoneUid,
                lastSeen: now,
                verified: KNOWN_UUIDS.contains(uuid.toUpperCase()),
              );
            }
            break;
          case 0x10: // Eddystone-URL
            if (eddystoneData.length > 2) {
              return BeaconDevice(
                deviceId: deviceId,
                name: name.isNotEmpty ? name : 'Eddystone-URL',
                rssi: rssi,
                uuid: 'URL-${deviceId.substring(0, 8)}',
                major: 0,
                minor: 0,
                protocol: BeaconProtocol.eddystoneUrl,
                lastSeen: now,
                verified: false,
              );
            }
            break;
        }
      }
    } catch (e) {
      print('Error parsing Eddystone: $e');
    }

    return null;
  }

  /// Parsea dispositivo BLE genérico
  static BeaconDevice tryParseGenericBLE(
    String deviceId,
    String name,
    int rssi,
    Uint8List? manufacturerData,
  ) {
    String uuid = deviceId.replaceAll(':', '').toUpperCase();
    if (uuid.length >= 32) {
      uuid = uuid.substring(0, 32);
    }

    // Verificar si el nombre contiene "Holy" u otros patrones conocidos
    bool isKnownDevice =
        name.toLowerCase().contains('holy') ||
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
  static String _formatUuid(Uint8List bytes) {
    if (bytes.length < 16) return '';

    String hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
    return _insertUuidDashes(hex);
  }

  static String _insertUuidDashes(String hex) {
    if (hex.length < 32) return hex;

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  static String _getDeviceNameFromUuid(String uuid) {
    switch (uuid.toUpperCase()) {
      case HOLY_SHUN_UUID:
        return 'Holy-Shun';
      case HOLY_JIN_UUID:
        return 'Holy-Jin';
      case KRONOS_BLAZE_UUID:
        return 'Kronos Blaze BLE';
      default:
        return 'Unknown Device';
    }
  }
}
