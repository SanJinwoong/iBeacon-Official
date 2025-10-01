import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

void main() {
  group('UuidProcessor - Single UUID Processing', () {
    test('should process valid Holy Shun UUID correctly', () {
      const uuid = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';
      final result = UuidProcessor.processSingleUuid(uuid);

      expect(result.isValid, true);
      expect(result.isHolyDevice, true);
      expect(result.deviceCategory, HolyDeviceCategory.shun);
      expect(result.deviceType, 'Holy Shun Device');
      expect(result.trustLevel, 10);
      expect(result.normalizedUuid, uuid);
    });

    test('should process valid Holy Jin UUID correctly', () {
      const uuid = 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000';
      final result = UuidProcessor.processSingleUuid(uuid);

      expect(result.isValid, true);
      expect(result.isHolyDevice, true);
      expect(result.deviceCategory, HolyDeviceCategory.jin);
      expect(result.deviceType, 'Holy Jin Device');
      expect(result.trustLevel, 10);
    });

    test('should process valid Kronos UUID correctly', () {
      const uuid = 'F7826DA6-4FA2-4E98-8024-BC5B71E0893E';
      final result = UuidProcessor.processSingleUuid(uuid);

      expect(result.isValid, true);
      expect(result.isHolyDevice, true);
      expect(result.deviceCategory, HolyDeviceCategory.kronos);
      expect(result.deviceType, 'Kronos Blaze Device');
      expect(result.trustLevel, 9);
    });

    test('should handle non-Holy UUID correctly', () {
      const uuid = '12345678-1234-5678-9012-123456789012';
      final result = UuidProcessor.processSingleUuid(uuid);

      expect(result.isValid, true);
      expect(result.isHolyDevice, false);
      expect(result.deviceCategory, HolyDeviceCategory.unknown);
      expect(result.deviceType, 'Generic Device');
      expect(result.trustLevel, 1);
    });

    test('should normalize UUID format correctly', () {
      const inputUuid =
          'fda50693a4e24fb1afcfc6eb07647825'; // lowercase, no dashes
      const expectedUuid = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';

      final result =
          UuidProcessor.processSingleUuid(inputUuid, normalizeFormat: true);

      expect(result.isValid, true);
      expect(result.normalizedUuid, expectedUuid);
      expect(result.isHolyDevice, true);
    });

    test('should handle empty UUID', () {
      const uuid = '';
      final result = UuidProcessor.processSingleUuid(uuid);

      expect(result.isValid, false);
      expect(result.errorType, UuidErrorType.emptyUuid);
      expect(result.errorMessage, 'UUID cannot be empty');
    });

    test('should handle invalid UUID format', () {
      const uuid = 'invalid-uuid-format';
      final result =
          UuidProcessor.processSingleUuid(uuid, validateFormat: true);

      expect(result.isValid, false);
      expect(result.errorType, UuidErrorType.invalidFormat);
      expect(result.errorMessage?.contains('Invalid UUID format'), true);
    });

    test('should handle case insensitive Holy device detection', () {
      const lowercaseUuid = 'fda50693-a4e2-4fb1-afcf-c6eb07647825';
      final result = UuidProcessor.processSingleUuid(lowercaseUuid);

      expect(result.isValid, true);
      expect(result.isHolyDevice, true);
      expect(result.deviceCategory, HolyDeviceCategory.shun);
    });
  });

  group('UuidProcessor - UUID List Processing', () {
    test('should process mixed UUID list correctly', () {
      final uuids = [
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy Shun
        'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy Jin
        '12345678-1234-5678-9012-123456789012', // Generic
        'invalid-uuid', // Invalid
        'F7826DA6-4FA2-4E98-8024-BC5B71E0893E', // Kronos
      ];

      final result = UuidProcessor.processUuidList(uuids);

      expect(result.totalProcessed, 5);
      expect(result.validCount, 4);
      expect(result.invalidCount, 1);
      expect(result.holyDeviceCount, 3);
      expect(result.successRate, 80.0);
      expect(result.holyDeviceRate, 75.0);
    });

    test('should filter invalid UUIDs when requested', () {
      final uuids = [
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        'invalid-uuid',
        'E2C56DB5-DFFB-48D2-B060-D0F5A7100000',
      ];

      final result = UuidProcessor.processUuidList(uuids, filterInvalid: true);

      expect(result.validResults.length, 2);
      expect(result.validResults.every((r) => r.isValid), true);
    });

    test('should prioritize Holy devices when requested', () {
      final uuids = [
        '12345678-1234-5678-9012-123456789012', // Generic
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy Shun
        'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy Jin
      ];

      final result = UuidProcessor.processUuidList(uuids, prioritizeHoly: true);

      expect(result.validResults.first.isHolyDevice, true);
      expect(result.validResults.last.isHolyDevice, false);
    });

    test('should handle empty UUID list', () {
      final result = UuidProcessor.processUuidList([]);

      expect(result.totalProcessed, 0);
      expect(result.validCount, 0);
      expect(result.holyDeviceCount, 0);
    });

    test('should normalize all UUIDs in list', () {
      final uuids = [
        'fda50693a4e24fb1afcfc6eb07647825', // lowercase, no dashes
        'E2C56DB5DFFB48D2B060D0F5A7100000', // uppercase, no dashes
      ];

      final result =
          UuidProcessor.processUuidList(uuids, normalizeFormat: true);

      expect(result.validResults[0].normalizedUuid,
          'FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
      expect(result.validResults[1].normalizedUuid,
          'E2C56DB5-DFFB-48D2-B060-D0F5A7100000');
    });
  });

  group('UuidProcessor - Format Validation and Normalization', () {
    test('should validate correct UUID format', () {
      const validUuids = [
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        '12345678-1234-5678-9012-123456789012',
        'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF',
      ];

      for (final uuid in validUuids) {
        expect(UuidProcessor.isValidUuidFormat(uuid), true,
            reason: 'UUID $uuid should be valid');
      }
    });

    test('should reject invalid UUID formats', () {
      const invalidUuids = [
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825-EXTRA',
        'FDA50693-A4E2-4FB1-AFCF',
        'not-a-uuid-at-all',
        '12345678123456789012345678901234', // no dashes
        '',
      ];

      for (final uuid in invalidUuids) {
        expect(UuidProcessor.isValidUuidFormat(uuid), false,
            reason: 'UUID $uuid should be invalid');
      }
    });

    test('should normalize various UUID formats', () {
      final testCases = {
        'fda50693a4e24fb1afcfc6eb07647825':
            'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        'FDA50693A4E24FB1AFCFC6EB07647825':
            'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        'fda50693-a4e2-4fb1-afcf-c6eb07647825':
            'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
        'fda50693_a4e2_4fb1_afcf_c6eb07647825':
            'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
      };

      testCases.forEach((input, expected) {
        final normalized = UuidProcessor.normalizeUuidFormat(input);
        expect(normalized, expected,
            reason: 'Input $input should normalize to $expected');
      });
    });

    test('should handle short UUIDs gracefully', () {
      const shortUuid = 'FDA50693-A4E2';
      final normalized = UuidProcessor.normalizeUuidFormat(shortUuid);

      expect(normalized,
          shortUuid); // Should return original for non-standard lengths
    });
  });

  group('UuidProcessor - Byte Conversion', () {
    test('should convert UUID to bytes correctly', () {
      const uuid = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';
      final bytes = UuidProcessor.uuidToBytes(uuid);

      expect(bytes.length, 16);
      expect(bytes[0], 0xFD);
      expect(bytes[1], 0xA5);
      expect(bytes[2], 0x06);
      expect(bytes[3], 0x93);
    });

    test('should convert bytes to UUID correctly', () {
      final bytes = Uint8List.fromList([
        0xFD,
        0xA5,
        0x06,
        0x93,
        0xA4,
        0xE2,
        0x4F,
        0xB1,
        0xAF,
        0xCF,
        0xC6,
        0xEB,
        0x07,
        0x64,
        0x78,
        0x25,
      ]);

      final uuid = UuidProcessor.bytesToUuid(bytes);
      expect(uuid, 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
    });

    test('should round-trip bytes to UUID and back', () {
      const originalUuid = 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000';
      final bytes = UuidProcessor.uuidToBytes(originalUuid);
      final convertedUuid = UuidProcessor.bytesToUuid(bytes);

      expect(convertedUuid, originalUuid);
    });

    test('should throw error for invalid UUID in uuidToBytes', () {
      expect(() => UuidProcessor.uuidToBytes('invalid'), throwsArgumentError);
      expect(() => UuidProcessor.uuidToBytes(''), throwsArgumentError);
    });

    test('should throw error for insufficient bytes in bytesToUuid', () {
      final shortBytes = Uint8List.fromList([0xFD, 0xA5]); // Only 2 bytes
      expect(() => UuidProcessor.bytesToUuid(shortBytes), throwsArgumentError);
    });
  });

  group('UuidProcessor - Edge Cases and Error Handling', () {
    test('should handle null-like inputs gracefully', () {
      final result = UuidProcessor.processSingleUuid('');
      expect(result.isValid, false);
      expect(result.errorType, UuidErrorType.emptyUuid);
    });

    test('should provide meaningful error messages', () {
      final invalidResult = UuidProcessor.processSingleUuid('invalid-uuid');
      expect(invalidResult.errorMessage, isNotNull);
      expect(invalidResult.errorMessage!.contains('Invalid UUID format'), true);
    });

    test('should handle malformed UUID gracefully', () {
      const malformedUuid = 'FDA50693-A4E2-4FB1-AFCF-C6EB0764782X'; // X at end
      final result =
          UuidProcessor.processSingleUuid(malformedUuid, validateFormat: true);

      expect(result.isValid, false);
      expect(result.errorType, UuidErrorType.invalidFormat);
    });

    test('should provide useful toString representation', () {
      final validResult = UuidProcessor.processSingleUuid(
          'FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
      final toString = validResult.toString();

      expect(toString.contains('FDA50693-A4E2-4FB1-AFCF-C6EB07647825'), true);
      expect(toString.contains('holy: true'), true);
    });

    test('should provide useful toString for list results', () {
      final result = UuidProcessor.processUuidList(
          ['FDA50693-A4E2-4FB1-AFCF-C6EB07647825', 'invalid-uuid']);

      final toString = result.toString();
      expect(toString.contains('total: 2'), true);
      expect(toString.contains('valid: 1'), true);
      expect(toString.contains('holy: 1'), true);
    });
  });

  group('UuidProcessor - Performance and Scalability', () {
    test('should handle large UUID lists efficiently', () {
      // Generate a large list of UUIDs (mix of valid and invalid)
      final largeUuidList = <String>[];
      for (int i = 0; i < 1000; i++) {
        if (i % 100 == 0) {
          largeUuidList.add('FDA50693-A4E2-4FB1-AFCF-C6EB07647825'); // Holy
        } else if (i % 50 == 0) {
          largeUuidList.add('invalid-uuid-$i'); // Invalid
        } else {
          largeUuidList.add(
              '12345678-1234-5678-9012-${i.toString().padLeft(12, '0')}'); // Valid generic
        }
      }

      final stopwatch = Stopwatch()..start();
      final result = UuidProcessor.processUuidList(largeUuidList);
      stopwatch.stop();

      expect(result.totalProcessed, 1000);
      expect(result.holyDeviceCount, 10); // Every 100th item
      expect(stopwatch.elapsedMilliseconds, lessThan(1000),
          reason: 'Should process 1000 UUIDs in under 1 second');
    });
  });
}
