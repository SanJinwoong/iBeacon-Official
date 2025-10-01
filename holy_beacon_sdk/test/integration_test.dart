import 'package:flutter_test/flutter_test.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

void main() {
  group('HolyBeaconScanner Integration Tests', () {
    late HolyBeaconScanner scanner;

    setUp(() {
      scanner = HolyBeaconScanner();
    });

    tearDown(() {
      scanner.dispose();
    });

    test('should initialize correctly', () async {
      await scanner.initialize();
      expect(scanner.isScanning, false);
    });

    test('should detect Holy devices correctly', () {
      final holyDevice = BeaconDevice(
        deviceId: 'test-id-holy',
        name: 'Holy-IOT Jin',
        rssi: -50,
        uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000',
        major: 1,
        minor: 2,
        protocol: BeaconProtocol.ibeacon,
        lastSeen: DateTime.now(),
        verified: true,
      );

      expect(holyDevice.isHolyDevice, true);
      expect(holyDevice.verified, true);
      expect(holyDevice.protocol, BeaconProtocol.ibeacon);
    });

    test('should filter generic devices correctly', () {
      final genericDevice = BeaconDevice(
        deviceId: 'test-id-generic',
        name: 'Generic BLE Device',
        rssi: -60,
        uuid: '12345678-1234-5678-9012-123456789012',
        major: 0,
        minor: 0,
        protocol: BeaconProtocol.bleDevice,
        lastSeen: DateTime.now(),
        verified: false,
      );

      expect(genericDevice.isHolyDevice, false);
      expect(genericDevice.verified, false);
      expect(genericDevice.protocol, BeaconProtocol.bleDevice);
    });

    test('should create optimized scan config', () {
      final config = BeaconScanConfig.holyOptimized();

      expect(config.prioritizeHolyDevices, true);
      expect(config.minRssi, lessThan(0));
    });

    test('should create whitelist for Holy devices only', () {
      final whitelist = BeaconWhitelist.holyDevicesOnly();

      final holyDevice = BeaconDevice(
        deviceId: 'holy-test',
        name: 'Holy Device',
        rssi: -50,
        uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        major: 1,
        minor: 1,
        protocol: BeaconProtocol.ibeacon,
        lastSeen: DateTime.now(),
        verified: true,
      );

      final genericDevice = BeaconDevice(
        deviceId: 'generic-test',
        name: 'Generic Device',
        rssi: -60,
        uuid: '12345678-1234-5678-9012-123456789012',
        major: 0,
        minor: 0,
        protocol: BeaconProtocol.bleDevice,
        lastSeen: DateTime.now(),
        verified: false,
      );

      expect(whitelist.isAllowed(holyDevice), true);
      expect(whitelist.isAllowed(genericDevice), false);
    });
  });

  group('BeaconParsers Tests', () {
    test('should validate UUID formats correctly', () {
      expect(BeaconParsers.isValidUuid('FDA50693-A4E2-4FB1-AFCF-C6EB07647825'),
          true);
      expect(BeaconParsers.isValidUuid('invalid-uuid'), false);
      expect(BeaconParsers.isValidUuid(''), false);
    });

    test('should detect Holy devices by name', () {
      expect(BeaconParsers.isHolyDevice('device1', 'Holy-IOT Jin'), true);
      expect(BeaconParsers.isHolyDevice('device2', 'Kronos Blaze'), true);
      expect(BeaconParsers.isHolyDevice('device3', 'Generic Device'), false);
    });
  });

  group('BeaconUtils Tests', () {
    test('should calculate distance correctly', () {
      final distance = BeaconUtils.calculateDistance(rssi: -50, txPower: -59);
      expect(distance, greaterThan(0));
      expect(distance, lessThan(100)); // Should be reasonable distance
    });

    test('should determine accuracy levels correctly', () {
      expect(BeaconUtils.getAccuracyLevel(-30), BeaconAccuracy.immediate);
      expect(BeaconUtils.getAccuracyLevel(-50), BeaconAccuracy.near);
      expect(BeaconUtils.getAccuracyLevel(-70), BeaconAccuracy.far);
      expect(BeaconUtils.getAccuracyLevel(-90), BeaconAccuracy.unknown);
    });

    test('should format UUIDs consistently', () {
      final formatted =
          BeaconUtils.formatUuid('fda50693a4e24fb1afcfc6eb07647825');
      expect(formatted, 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
    });

    test('should validate UUID formats', () {
      expect(BeaconUtils.isValidUuid('FDA50693-A4E2-4FB1-AFCF-C6EB07647825'),
          true);
      expect(BeaconUtils.isValidUuid('invalid'), false);
    });
  });

  group('UUID Processor Integration with Beacon Models', () {
    test('should integrate UUID processing with beacon detection', () {
      const testUuid = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';

      // Process UUID
      final uuidResult = UuidProcessor.processSingleUuid(testUuid);
      expect(uuidResult.isHolyDevice, true);
      expect(uuidResult.deviceCategory, HolyDeviceCategory.shun);

      // Create beacon device with same UUID
      final beaconDevice = BeaconDevice(
        deviceId: 'test-beacon',
        name: 'Test Beacon',
        rssi: -50,
        uuid: testUuid,
        major: 1,
        minor: 1,
        protocol: BeaconProtocol.ibeacon,
        lastSeen: DateTime.now(),
        verified: uuidResult.isHolyDevice,
      );

      expect(beaconDevice.isHolyDevice, uuidResult.isHolyDevice);
      expect(beaconDevice.verified, true);
    });

    test('should process multiple UUIDs for whitelist creation', () {
      final uuids = [
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy Shun
        'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy Jin
        '12345678-1234-5678-9012-123456789012', // Generic
      ];

      final result = UuidProcessor.processUuidList(uuids);
      final holyUuids = result.holyResults.map((r) => r.normalizedUuid).toSet();

      final whitelist = BeaconWhitelist.uuidsOnly(holyUuids);

      // Test Holy device
      final holyDevice = BeaconDevice(
        deviceId: 'holy-test',
        name: 'Holy Device',
        rssi: -50,
        uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        major: 1,
        minor: 1,
        protocol: BeaconProtocol.ibeacon,
        lastSeen: DateTime.now(),
      );

      // Test generic device
      final genericDevice = BeaconDevice(
        deviceId: 'generic-test',
        name: 'Generic Device',
        rssi: -60,
        uuid: '12345678-1234-5678-9012-123456789012',
        major: 0,
        minor: 0,
        protocol: BeaconProtocol.bleDevice,
        lastSeen: DateTime.now(),
      );

      expect(whitelist.isAllowed(holyDevice), true);
      expect(whitelist.isAllowed(genericDevice), false);
    });
  });
}
