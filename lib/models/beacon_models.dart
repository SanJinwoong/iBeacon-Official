enum BeaconProtocol {
  ibeacon,
  eddystoneUid,
  eddystoneUrl,
  bleDevice,
}

class BeaconDevice {
  final String deviceId;
  final String name;
  final int rssi;
  final String uuid;
  final int major;
  final int minor;
  final BeaconProtocol protocol;
  final DateTime lastSeen;
  final bool verified;

  BeaconDevice({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.uuid,
    required this.major,
    required this.minor,
    required this.protocol,
    required this.lastSeen,
    this.verified = false,
  });

  /// Returns true if this is one of the "Holy" devices we're specifically looking for
  bool get isHolyDevice {
    const holyUuids = [
      'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // HOLY_SHUN_UUID
      'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // HOLY_JIN_UUID
      'F7826DA6-4FA2-4E98-8024-BC5B71E0893E', // KRONOS_BLAZE_UUID
    ];

    return holyUuids.contains(uuid.toUpperCase()) ||
        name.toLowerCase().contains('holy') ||
        name.toLowerCase().contains('kronos') ||
        name.toLowerCase().contains('blaze');
  }

  /// Returns signal strength as a percentage (0-100)
  int get signalStrengthPercent {
    // RSSI typically ranges from -30 (very close) to -100 (far away)
    // Convert to percentage where -30 = 100% and -100 = 0%
    final normalized = ((rssi + 100) / 70 * 100).clamp(0, 100);
    return normalized.round();
  }

  /// Returns a human-readable distance estimate
  String get estimatedDistance {
    if (rssi > -40) return 'Muy cerca (< 1m)';
    if (rssi > -60) return 'Cerca (1-3m)';
    if (rssi > -80) return 'Medio (3-10m)';
    if (rssi > -95) return 'Lejos (10-30m)';
    return 'Muy lejos (> 30m)';
  }

  /// Creates a copy of this BeaconDevice with updated fields
  BeaconDevice copyWith({
    String? deviceId,
    String? name,
    int? rssi,
    String? uuid,
    int? major,
    int? minor,
    BeaconProtocol? protocol,
    DateTime? lastSeen,
    bool? verified,
  }) {
    return BeaconDevice(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      uuid: uuid ?? this.uuid,
      major: major ?? this.major,
      minor: minor ?? this.minor,
      protocol: protocol ?? this.protocol,
      lastSeen: lastSeen ?? this.lastSeen,
      verified: verified ?? this.verified,
    );
  }

  /// Updates the last seen timestamp and optionally other fields
  BeaconDevice updateSeen({
    int? rssi,
    DateTime? lastSeen,
  }) {
    return copyWith(
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'BeaconDevice(name: $name, uuid: $uuid, rssi: $rssi, protocol: ${protocol.name}, verified: $verified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BeaconDevice &&
        other.deviceId == deviceId &&
        other.protocol == protocol;
  }

  @override
  int get hashCode => deviceId.hashCode ^ protocol.hashCode;
}

class BeaconWhitelist {
  final Set<String> allowedUuids;
  final Set<String> allowedNames;
  final bool allowUnknown;

  const BeaconWhitelist({
    this.allowedUuids = const {},
    this.allowedNames = const {},
    this.allowUnknown = true,
  });

  /// Creates a whitelist that only allows "Holy" devices
  factory BeaconWhitelist.holyDevicesOnly() {
    return const BeaconWhitelist(
      allowedUuids: {
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // HOLY_SHUN_UUID
        'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // HOLY_JIN_UUID
        'F7826DA6-4FA2-4E98-8024-BC5B71E0893E', // KRONOS_BLAZE_UUID
      },
      allowedNames: {
        'Holy-Shun',
        'Holy-Jin',
        'Kronos Blaze BLE',
      },
      allowUnknown: false,
    );
  }

  /// Creates a whitelist that allows all devices
  factory BeaconWhitelist.allowAll() {
    return const BeaconWhitelist(
      allowUnknown: true,
    );
  }

  /// Checks if a beacon device is allowed by this whitelist
  bool isAllowed(BeaconDevice device) {
    if (allowedUuids.contains(device.uuid.toUpperCase())) {
      return true;
    }

    if (allowedNames.any(
        (name) => device.name.toLowerCase().contains(name.toLowerCase()))) {
      return true;
    }

    return allowUnknown;
  }
}
