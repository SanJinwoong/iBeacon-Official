import '../models/beacon_models.dart';

/// Utility functions for beacon operations
class BeaconUtils {
  /// Calculate distance estimate from RSSI and TX Power
  /// 
  /// Uses the standard formula for RSSI-based distance estimation:
  /// Distance = 10^((TX_Power - RSSI) / (10 * N))
  /// Where N is the path loss exponent (typically 2 for free space)
  static double calculateDistance({
    required int rssi,
    int txPower = -59,
    double pathLossExponent = 2.0,
  }) {
    if (rssi == 0) return -1.0;
    
    final ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) {
      return math.pow(ratio, 10).toDouble();
    } else {
      final accuracy = (0.89976) * math.pow(ratio, 7.7095) + 0.111;
      return accuracy;
    }
  }

  /// Get accuracy level based on RSSI
  static BeaconAccuracy getAccuracyLevel(int rssi) {
    if (rssi > -40) return BeaconAccuracy.immediate;
    if (rssi > -60) return BeaconAccuracy.near;
    if (rssi > -80) return BeaconAccuracy.far;
    return BeaconAccuracy.unknown;
  }

  /// Format UUID string consistently
  static String formatUuid(String uuid) {
    if (uuid.isEmpty) return uuid;
    
    // Remove existing dashes and make uppercase
    final cleaned = uuid.replaceAll('-', '').toUpperCase();
    
    // Add dashes in proper positions
    if (cleaned.length == 32) {
      return '${cleaned.substring(0, 8)}-${cleaned.substring(8, 12)}-${cleaned.substring(12, 16)}-${cleaned.substring(16, 20)}-${cleaned.substring(20, 32)}';
    }
    
    return uuid; // Return original if not standard length
  }

  /// Check if UUID is valid format
  static bool isValidUuid(String uuid) {
    final pattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return pattern.hasMatch(uuid);
  }

  /// Convert RSSI to signal strength percentage (0-100)
  static int rssiToPercentage(int rssi) {
    // RSSI typically ranges from -30 (very close) to -100 (far away)
    // Convert to percentage where -30 = 100% and -100 = 0%
    final normalized = ((rssi + 100) / 70 * 100).clamp(0, 100);
    return normalized.round();
  }

  /// Get signal quality description from RSSI
  static String getSignalQuality(int rssi) {
    if (rssi > -50) return 'Excellent';
    if (rssi > -65) return 'Good';
    if (rssi > -80) return 'Fair';
    if (rssi > -95) return 'Poor';
    return 'Very Poor';
  }

  /// Get localized signal quality description
  static String getLocalizedSignalQuality(int rssi, String locale) {
    switch (locale) {
      case 'es':
        if (rssi > -50) return 'Excelente';
        if (rssi > -65) return 'Buena';
        if (rssi > -80) return 'Regular';
        if (rssi > -95) return 'Mala';
        return 'Muy Mala';
      default:
        return getSignalQuality(rssi);
    }
  }

  /// Sort devices with Holy devices prioritized
  static List<BeaconDevice> sortDevicesWithHolyPriority(List<BeaconDevice> devices) {
    final sorted = List<BeaconDevice>.from(devices);
    sorted.sort((a, b) {
      // Holy devices first
      if (a.isHolyDevice && !b.isHolyDevice) return -1;
      if (!a.isHolyDevice && b.isHolyDevice) return 1;
      
      // Within same category, sort by RSSI (stronger first)
      return b.rssi.compareTo(a.rssi);
    });
    return sorted;
  }

  /// Filter devices by minimum RSSI threshold
  static List<BeaconDevice> filterByRssi(List<BeaconDevice> devices, int minRssi) {
    return devices.where((device) => device.rssi >= minRssi).toList();
  }

  /// Filter devices by maximum age (time since last seen)
  static List<BeaconDevice> filterByAge(List<BeaconDevice> devices, Duration maxAge) {
    final now = DateTime.now();
    return devices.where((device) {
      final age = now.difference(device.lastSeen);
      return age <= maxAge;
    }).toList();
  }

  /// Group devices by protocol
  static Map<BeaconProtocol, List<BeaconDevice>> groupByProtocol(List<BeaconDevice> devices) {
    final grouped = <BeaconProtocol, List<BeaconDevice>>{};
    
    for (final device in devices) {
      grouped.putIfAbsent(device.protocol, () => <BeaconDevice>[]).add(device);
    }
    
    return grouped;
  }

  /// Get devices within proximity range
  static List<BeaconDevice> getDevicesInRange(
    List<BeaconDevice> devices,
    BeaconAccuracy maxAccuracy,
  ) {
    return devices.where((device) {
      final accuracy = getAccuracyLevel(device.rssi);
      return accuracy.index <= maxAccuracy.index;
    }).toList();
  }

  /// Generate device summary statistics
  static BeaconDeviceStats generateStats(List<BeaconDevice> devices) {
    if (devices.isEmpty) {
      return const BeaconDeviceStats(
        totalCount: 0,
        holyCount: 0,
        verifiedCount: 0,
        protocolCounts: {},
        averageRssi: 0,
        strongestRssi: 0,
        weakestRssi: 0,
      );
    }

    final protocolCounts = <BeaconProtocol, int>{};
    int totalRssi = 0;
    int strongestRssi = devices.first.rssi;
    int weakestRssi = devices.first.rssi;
    int holyCount = 0;
    int verifiedCount = 0;

    for (final device in devices) {
      protocolCounts[device.protocol] = (protocolCounts[device.protocol] ?? 0) + 1;
      totalRssi += device.rssi;
      
      if (device.rssi > strongestRssi) strongestRssi = device.rssi;
      if (device.rssi < weakestRssi) weakestRssi = device.rssi;
      
      if (device.isHolyDevice) holyCount++;
      if (device.verified) verifiedCount++;
    }

    return BeaconDeviceStats(
      totalCount: devices.length,
      holyCount: holyCount,
      verifiedCount: verifiedCount,
      protocolCounts: protocolCounts,
      averageRssi: totalRssi / devices.length,
      strongestRssi: strongestRssi,
      weakestRssi: weakestRssi,
    );
  }

  /// Convert hex string to byte array
  static List<int> hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Convert byte array to hex string
  static String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }
}

/// Beacon accuracy/proximity levels
enum BeaconAccuracy {
  immediate, // Very close (< 1m)
  near,      // Close (1-3m)
  far,       // Far (3m+)
  unknown,   // Cannot determine
}

/// Statistics about a collection of beacon devices
class BeaconDeviceStats {
  final int totalCount;
  final int holyCount;
  final int verifiedCount;
  final Map<BeaconProtocol, int> protocolCounts;
  final double averageRssi;
  final int strongestRssi;
  final int weakestRssi;

  const BeaconDeviceStats({
    required this.totalCount,
    required this.holyCount,
    required this.verifiedCount,
    required this.protocolCounts,
    required this.averageRssi,
    required this.strongestRssi,
    required this.weakestRssi,
  });

  /// Get count for specific protocol
  int getProtocolCount(BeaconProtocol protocol) {
    return protocolCounts[protocol] ?? 0;
  }

  /// Get percentage of Holy devices
  double get holyPercentage {
    if (totalCount == 0) return 0.0;
    return (holyCount / totalCount) * 100;
  }

  /// Get percentage of verified devices
  double get verifiedPercentage {
    if (totalCount == 0) return 0.0;
    return (verifiedCount / totalCount) * 100;
  }

  @override
  String toString() {
    return 'BeaconDeviceStats(total: $totalCount, holy: $holyCount, verified: $verifiedCount, avgRssi: ${averageRssi.toStringAsFixed(1)})';
  }
}

// Import math library for calculations
import 'dart:math' as math;