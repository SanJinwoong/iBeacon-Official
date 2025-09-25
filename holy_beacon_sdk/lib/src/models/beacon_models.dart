/// Beacon protocol enumeration
enum BeaconProtocol {
  /// Apple iBeacon protocol
  ibeacon,

  /// Google Eddystone UID protocol
  eddystoneUid,

  /// Google Eddystone URL protocol
  eddystoneUrl,

  /// Generic BLE device (non-beacon)
  bleDevice,
}

/// Represents a detected beacon device with all relevant information
class BeaconDevice {
  /// Unique device identifier (MAC address)
  final String deviceId;

  /// Human-readable device name
  final String name;

  /// Received Signal Strength Indicator in dBm
  final int rssi;

  /// Beacon UUID (Universally Unique Identifier)
  final String uuid;

  /// Major value for iBeacon protocol
  final int major;

  /// Minor value for iBeacon protocol
  final int minor;

  /// Protocol type of this beacon
  final BeaconProtocol protocol;

  /// Timestamp when this device was last seen
  final DateTime lastSeen;

  /// Whether this device has been verified/validated
  final bool verified;

  const BeaconDevice({
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
    if (rssi > -40) return 'Very close (< 1m)';
    if (rssi > -60) return 'Close (1-3m)';
    if (rssi > -80) return 'Medium (3-10m)';
    if (rssi > -95) return 'Far (10-30m)';
    return 'Very far (> 30m)';
  }

  /// Returns localized distance estimate
  String getLocalizedDistance(String locale) {
    switch (locale) {
      case 'es':
        if (rssi > -40) return 'Muy cerca (< 1m)';
        if (rssi > -60) return 'Cerca (1-3m)';
        if (rssi > -80) return 'Medio (3-10m)';
        if (rssi > -95) return 'Lejos (10-30m)';
        return 'Muy lejos (> 30m)';
      default:
        return estimatedDistance;
    }
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

  /// Converts this beacon device to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'rssi': rssi,
      'uuid': uuid,
      'major': major,
      'minor': minor,
      'protocol': protocol.name,
      'lastSeen': lastSeen.millisecondsSinceEpoch,
      'verified': verified,
      'isHolyDevice': isHolyDevice,
      'signalStrengthPercent': signalStrengthPercent,
      'estimatedDistance': estimatedDistance,
    };
  }

  /// Creates a BeaconDevice from a JSON map
  factory BeaconDevice.fromJson(Map<String, dynamic> json) {
    return BeaconDevice(
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      rssi: json['rssi'] as int,
      uuid: json['uuid'] as String,
      major: json['major'] as int,
      minor: json['minor'] as int,
      protocol: BeaconProtocol.values.firstWhere(
        (e) => e.name == json['protocol'],
        orElse: () => BeaconProtocol.bleDevice,
      ),
      lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int),
      verified: json['verified'] as bool? ?? false,
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

/// Scan configuration for beacon scanning
class BeaconScanConfig {
  /// Duration for which the scan should run (null = indefinite)
  final Duration? scanDuration;

  /// Minimum RSSI threshold for devices to be included
  final int? minRssi;

  /// Whether to prioritize Holy devices in results
  final bool prioritizeHolyDevices;

  /// Whether to enable debug logging
  final bool enableDebugLogs;

  /// Custom scan interval (Android only)
  final Duration? scanInterval;

  const BeaconScanConfig({
    this.scanDuration,
    this.minRssi,
    this.prioritizeHolyDevices = true,
    this.enableDebugLogs = false,
    this.scanInterval,
  });

  /// Default configuration optimized for Holy device detection
  factory BeaconScanConfig.holyOptimized() {
    return const BeaconScanConfig(
      scanDuration: Duration(seconds: 30),
      minRssi: -100,
      prioritizeHolyDevices: true,
      enableDebugLogs: true,
    );
  }

  /// Configuration for continuous scanning
  factory BeaconScanConfig.continuous() {
    return const BeaconScanConfig(
      prioritizeHolyDevices: true,
      enableDebugLogs: false,
    );
  }
}
