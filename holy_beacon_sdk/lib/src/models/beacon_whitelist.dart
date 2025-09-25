import 'beacon_models.dart';

/// Whitelist configuration for filtering beacon devices
class BeaconWhitelist {
  /// Set of allowed UUIDs (case-insensitive)
  final Set<String> allowedUuids;

  /// Set of allowed device names (case-insensitive substring matching)
  final Set<String> allowedNames;

  /// Whether to allow devices that don't match UUID or name filters
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
        'holy-shun',
        'holy-jin',
        'holy-iot',
        'kronos blaze ble',
        'holy',
        'kronos',
        'blaze',
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

  /// Creates a whitelist for specific UUIDs only
  factory BeaconWhitelist.uuidsOnly(Set<String> uuids) {
    return BeaconWhitelist(
      allowedUuids: uuids,
      allowUnknown: false,
    );
  }

  /// Creates a whitelist for specific device names only
  factory BeaconWhitelist.namesOnly(Set<String> names) {
    return BeaconWhitelist(
      allowedNames: names,
      allowUnknown: false,
    );
  }

  /// Checks if a beacon device is allowed by this whitelist
  bool isAllowed(BeaconDevice device) {
    // Check UUID whitelist
    if (allowedUuids.isNotEmpty) {
      final matchesUuid = allowedUuids.any(
        (uuid) => device.uuid.toUpperCase() == uuid.toUpperCase(),
      );
      if (matchesUuid) return true;
    }

    // Check name whitelist
    if (allowedNames.isNotEmpty) {
      final deviceNameLower = device.name.toLowerCase();
      final matchesName = allowedNames.any(
        (name) => deviceNameLower.contains(name.toLowerCase()),
      );
      if (matchesName) return true;
    }

    // If no specific filters matched, check allowUnknown
    return allowUnknown;
  }

  /// Returns a new whitelist with additional allowed UUIDs
  BeaconWhitelist addUuids(Set<String> uuids) {
    return BeaconWhitelist(
      allowedUuids: {...allowedUuids, ...uuids},
      allowedNames: allowedNames,
      allowUnknown: allowUnknown,
    );
  }

  /// Returns a new whitelist with additional allowed names
  BeaconWhitelist addNames(Set<String> names) {
    return BeaconWhitelist(
      allowedUuids: allowedUuids,
      allowedNames: {...allowedNames, ...names},
      allowUnknown: allowUnknown,
    );
  }

  /// Returns statistics about filtering results
  BeaconFilterStats getStats(List<BeaconDevice> allDevices) {
    final allowed = allDevices.where(isAllowed).toList();
    final blocked = allDevices.where((d) => !isAllowed(d)).toList();

    return BeaconFilterStats(
      totalDevices: allDevices.length,
      allowedDevices: allowed.length,
      blockedDevices: blocked.length,
      holyDevices: allowed.where((d) => d.isHolyDevice).length,
      allowedDevicesList: allowed,
      blockedDevicesList: blocked,
    );
  }

  @override
  String toString() {
    return 'BeaconWhitelist(uuids: ${allowedUuids.length}, names: ${allowedNames.length}, allowUnknown: $allowUnknown)';
  }
}

/// Statistics about beacon filtering results
class BeaconFilterStats {
  final int totalDevices;
  final int allowedDevices;
  final int blockedDevices;
  final int holyDevices;
  final List<BeaconDevice> allowedDevicesList;
  final List<BeaconDevice> blockedDevicesList;

  const BeaconFilterStats({
    required this.totalDevices,
    required this.allowedDevices,
    required this.blockedDevices,
    required this.holyDevices,
    required this.allowedDevicesList,
    required this.blockedDevicesList,
  });

  /// Returns the percentage of allowed devices
  double get allowedPercentage {
    if (totalDevices == 0) return 0.0;
    return (allowedDevices / totalDevices) * 100;
  }

  /// Returns the percentage of Holy devices among allowed devices
  double get holyDevicePercentage {
    if (allowedDevices == 0) return 0.0;
    return (holyDevices / allowedDevices) * 100;
  }

  @override
  String toString() {
    return 'BeaconFilterStats(total: $totalDevices, allowed: $allowedDevices, blocked: $blockedDevices, holy: $holyDevices)';
  }
}
