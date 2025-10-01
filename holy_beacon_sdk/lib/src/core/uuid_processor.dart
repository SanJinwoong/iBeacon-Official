import 'dart:typed_data';

/// Core UUID processing functionality for Holy Beacon SDK
///
/// This class provides the fundamental UUID processing logic that can be
/// used across all platforms (Flutter, Android, iOS) as part of larger systems.
///
/// Key Features:
/// - Process single UUIDs or lists of UUIDs
/// - Validation and normalization
/// - Holy device detection and verification
/// - Format conversion and error handling
/// - Scalable for integration into larger systems
class UuidProcessor {
  /// Known UUIDs for Holy devices - the core business logic
  static const List<String> holyShunUuids = [
    'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
  ];

  static const List<String> holyJinUuids = [
    'E2C56DB5-DFFB-48D2-B060-D0F5A7100000',
  ];

  static const List<String> kronosUuids = [
    'F7826DA6-4FA2-4E98-8024-BC5B71E0893E',
  ];

  /// Combined list of all known Holy device UUIDs
  static const List<String> knownHolyUuids = [
    ...holyShunUuids,
    ...holyJinUuids,
    ...kronosUuids,
  ];

  /// Process a single UUID with validation, normalization, and Holy device detection
  ///
  /// Parameters:
  /// - [uuid]: The UUID string to process
  /// - [validateFormat]: Whether to perform strict format validation
  /// - [normalizeFormat]: Whether to normalize the UUID format
  ///
  /// Returns [UuidProcessingResult] with processing outcome
  ///
  /// Example:
  /// ```dart
  /// final result = UuidProcessor.processSingleUuid(
  ///   'fda50693-a4e2-4fb1-afcf-c6eb07647825',
  ///   validateFormat: true,
  ///   normalizeFormat: true,
  /// );
  ///
  /// if (result.isValid) {
  ///   print('UUID: ${result.normalizedUuid}');
  ///   print('Is Holy device: ${result.isHolyDevice}');
  ///   print('Device category: ${result.deviceCategory}');
  /// }
  /// ```
  static UuidProcessingResult processSingleUuid(
    String uuid, {
    bool validateFormat = true,
    bool normalizeFormat = true,
  }) {
    try {
      // Handle null or empty UUID
      if (uuid.isEmpty) {
        return UuidProcessingResult.error(
          originalUuid: uuid,
          errorType: UuidErrorType.emptyUuid,
          errorMessage: 'UUID cannot be empty',
        );
      }

      // Normalize format first
      String processedUuid = uuid;
      if (normalizeFormat) {
        processedUuid = normalizeUuidFormat(uuid);
      }

      // Validate format if requested
      if (validateFormat && !isValidUuidFormat(processedUuid)) {
        return UuidProcessingResult.error(
          originalUuid: uuid,
          errorType: UuidErrorType.invalidFormat,
          errorMessage: 'Invalid UUID format: $uuid',
        );
      }

      // Detect Holy device category
      final deviceInfo = _detectHolyDevice(processedUuid);

      return UuidProcessingResult.success(
        originalUuid: uuid,
        normalizedUuid: processedUuid,
        isHolyDevice: deviceInfo.isHoly,
        deviceCategory: deviceInfo.category,
        deviceType: deviceInfo.type,
        trustLevel: deviceInfo.trustLevel,
      );
    } catch (e) {
      return UuidProcessingResult.error(
        originalUuid: uuid,
        errorType: UuidErrorType.processingError,
        errorMessage: 'Processing error: $e',
      );
    }
  }

  /// Process a list of UUIDs with comprehensive filtering and categorization
  ///
  /// Parameters:
  /// - [uuids]: List of UUID strings to process
  /// - [filterInvalid]: Whether to exclude invalid UUIDs from results
  /// - [prioritizeHoly]: Whether to sort Holy devices first
  /// - [validateFormat]: Whether to perform strict format validation
  /// - [normalizeFormat]: Whether to normalize UUID formats
  ///
  /// Returns [UuidListProcessingResult] with categorized results
  ///
  /// Example:
  /// ```dart
  /// final uuids = [
  ///   'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy Shun
  ///   'invalid-uuid',
  ///   'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy Jin
  /// ];
  ///
  /// final result = UuidProcessor.processUuidList(
  ///   uuids,
  ///   filterInvalid: true,
  ///   prioritizeHoly: true,
  /// );
  ///
  /// print('Total processed: ${result.totalProcessed}');
  /// print('Holy devices: ${result.holyDeviceCount}');
  /// print('Valid UUIDs: ${result.validResults.length}');
  /// ```
  static UuidListProcessingResult processUuidList(
    List<String> uuids, {
    bool filterInvalid = false,
    bool prioritizeHoly = false,
    bool validateFormat = true,
    bool normalizeFormat = true,
  }) {
    if (uuids.isEmpty) {
      return UuidListProcessingResult.empty();
    }

    final List<UuidProcessingResult> allResults = [];
    final List<UuidProcessingResult> validResults = [];
    final List<UuidProcessingResult> invalidResults = [];
    final List<UuidProcessingResult> holyResults = [];

    // Process each UUID
    for (final uuid in uuids) {
      final result = processSingleUuid(
        uuid,
        validateFormat: validateFormat,
        normalizeFormat: normalizeFormat,
      );

      allResults.add(result);

      if (result.isValid) {
        validResults.add(result);
        if (result.isHolyDevice) {
          holyResults.add(result);
        }
      } else {
        invalidResults.add(result);
      }
    }

    // Sort results if prioritization is requested
    if (prioritizeHoly && validResults.isNotEmpty) {
      validResults.sort((a, b) {
        // Holy devices first, then by trust level, then alphabetical
        if (a.isHolyDevice && !b.isHolyDevice) return -1;
        if (!a.isHolyDevice && b.isHolyDevice) return 1;

        final trustComparison = b.trustLevel.compareTo(a.trustLevel);
        if (trustComparison != 0) return trustComparison;

        return a.normalizedUuid.compareTo(b.normalizedUuid);
      });
    }

    return UuidListProcessingResult(
      totalProcessed: uuids.length,
      allResults: filterInvalid ? validResults : allResults,
      validResults: validResults,
      invalidResults: invalidResults,
      holyResults: holyResults,
    );
  }

  /// Normalize UUID format to standard 8-4-4-4-12 format with uppercase
  ///
  /// Example:
  /// ```dart
  /// final normalized = UuidProcessor.normalizeUuidFormat('fda50693a4e24fb1afcfc6eb07647825');
  /// print(normalized); // FDA50693-A4E2-4FB1-AFCF-C6EB07647825
  /// ```
  static String normalizeUuidFormat(String uuid) {
    if (uuid.isEmpty) return uuid;

    // Remove all non-hex characters and convert to uppercase
    final cleanUuid =
        uuid.replaceAll(RegExp(r'[^0-9a-fA-F]'), '').toUpperCase();

    // Add dashes if we have exactly 32 hex characters
    if (cleanUuid.length == 32) {
      return '${cleanUuid.substring(0, 8)}-${cleanUuid.substring(8, 12)}-${cleanUuid.substring(12, 16)}-${cleanUuid.substring(16, 20)}-${cleanUuid.substring(20, 32)}';
    }

    return uuid; // Return original if not standard length
  }

  /// Validate UUID format according to RFC 4122
  ///
  /// Example:
  /// ```dart
  /// bool isValid = UuidProcessor.isValidUuidFormat('FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
  /// print(isValid); // true
  /// ```
  static bool isValidUuidFormat(String uuid) {
    if (uuid.isEmpty) return false;

    final pattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return pattern.hasMatch(uuid);
  }

  /// Convert byte array to UUID string
  ///
  /// Example:
  /// ```dart
  /// final bytes = Uint8List.fromList([0xFD, 0xA5, 0x06, 0x93, ...]);
  /// final uuid = UuidProcessor.bytesToUuid(bytes);
  /// ```
  static String bytesToUuid(Uint8List bytes) {
    if (bytes.length < 16) {
      throw ArgumentError('UUID bytes must be at least 16 bytes long');
    }

    final hex = bytes
        .take(16)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();

    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Convert UUID string to byte array
  ///
  /// Example:
  /// ```dart
  /// final bytes = UuidProcessor.uuidToBytes('FDA50693-A4E2-4FB1-AFCF-C6EB07647825');
  /// ```
  static Uint8List uuidToBytes(String uuid) {
    final cleanUuid = uuid.replaceAll('-', '');
    if (cleanUuid.length != 32) {
      throw ArgumentError('UUID must be 32 hex characters');
    }

    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      final hex = cleanUuid.substring(i * 2, i * 2 + 2);
      bytes[i] = int.parse(hex, radix: 16);
    }
    return bytes;
  }

  /// Internal method to detect Holy device information
  static _HolyDeviceInfo _detectHolyDevice(String normalizedUuid) {
    final upperUuid = normalizedUuid.toUpperCase();

    if (holyShunUuids.any((uuid) => uuid.toUpperCase() == upperUuid)) {
      return _HolyDeviceInfo(
        isHoly: true,
        category: HolyDeviceCategory.shun,
        type: 'Holy Shun Device',
        trustLevel: 10,
      );
    }

    if (holyJinUuids.any((uuid) => uuid.toUpperCase() == upperUuid)) {
      return _HolyDeviceInfo(
        isHoly: true,
        category: HolyDeviceCategory.jin,
        type: 'Holy Jin Device',
        trustLevel: 10,
      );
    }

    if (kronosUuids.any((uuid) => uuid.toUpperCase() == upperUuid)) {
      return _HolyDeviceInfo(
        isHoly: true,
        category: HolyDeviceCategory.kronos,
        type: 'Kronos Blaze Device',
        trustLevel: 9,
      );
    }

    return _HolyDeviceInfo(
      isHoly: false,
      category: HolyDeviceCategory.unknown,
      type: 'Generic Device',
      trustLevel: 1,
    );
  }
}

/// Internal class for Holy device information
class _HolyDeviceInfo {
  final bool isHoly;
  final HolyDeviceCategory category;
  final String type;
  final int trustLevel;

  const _HolyDeviceInfo({
    required this.isHoly,
    required this.category,
    required this.type,
    required this.trustLevel,
  });
}

/// Categories of Holy devices
enum HolyDeviceCategory {
  shun,
  jin,
  kronos,
  unknown,
}

/// Error types for UUID processing
enum UuidErrorType {
  emptyUuid,
  invalidFormat,
  processingError,
}

/// Result of processing a single UUID
class UuidProcessingResult {
  final String originalUuid;
  final String normalizedUuid;
  final bool isValid;
  final bool isHolyDevice;
  final HolyDeviceCategory deviceCategory;
  final String deviceType;
  final int trustLevel;
  final UuidErrorType? errorType;
  final String? errorMessage;

  const UuidProcessingResult._({
    required this.originalUuid,
    required this.normalizedUuid,
    required this.isValid,
    required this.isHolyDevice,
    required this.deviceCategory,
    required this.deviceType,
    required this.trustLevel,
    this.errorType,
    this.errorMessage,
  });

  factory UuidProcessingResult.success({
    required String originalUuid,
    required String normalizedUuid,
    required bool isHolyDevice,
    required HolyDeviceCategory deviceCategory,
    required String deviceType,
    required int trustLevel,
  }) {
    return UuidProcessingResult._(
      originalUuid: originalUuid,
      normalizedUuid: normalizedUuid,
      isValid: true,
      isHolyDevice: isHolyDevice,
      deviceCategory: deviceCategory,
      deviceType: deviceType,
      trustLevel: trustLevel,
    );
  }

  factory UuidProcessingResult.error({
    required String originalUuid,
    required UuidErrorType errorType,
    required String errorMessage,
  }) {
    return UuidProcessingResult._(
      originalUuid: originalUuid,
      normalizedUuid: originalUuid,
      isValid: false,
      isHolyDevice: false,
      deviceCategory: HolyDeviceCategory.unknown,
      deviceType: 'Error',
      trustLevel: 0,
      errorType: errorType,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (isValid) {
      return 'UuidProcessingResult(uuid: $normalizedUuid, holy: $isHolyDevice, category: $deviceCategory, trust: $trustLevel)';
    } else {
      return 'UuidProcessingResult(error: $errorType, message: $errorMessage)';
    }
  }
}

/// Result of processing a list of UUIDs
class UuidListProcessingResult {
  final int totalProcessed;
  final List<UuidProcessingResult> allResults;
  final List<UuidProcessingResult> validResults;
  final List<UuidProcessingResult> invalidResults;
  final List<UuidProcessingResult> holyResults;

  const UuidListProcessingResult({
    required this.totalProcessed,
    required this.allResults,
    required this.validResults,
    required this.invalidResults,
    required this.holyResults,
  });

  factory UuidListProcessingResult.empty() {
    return const UuidListProcessingResult(
      totalProcessed: 0,
      allResults: [],
      validResults: [],
      invalidResults: [],
      holyResults: [],
    );
  }

  /// Get count of valid UUIDs
  int get validCount => validResults.length;

  /// Get count of invalid UUIDs
  int get invalidCount => invalidResults.length;

  /// Get count of Holy devices
  int get holyDeviceCount => holyResults.length;

  /// Get success rate as percentage
  double get successRate =>
      totalProcessed > 0 ? (validCount / totalProcessed) * 100 : 0;

  /// Get Holy device rate as percentage
  double get holyDeviceRate =>
      validCount > 0 ? (holyDeviceCount / validCount) * 100 : 0;

  @override
  String toString() {
    return 'UuidListProcessingResult(total: $totalProcessed, valid: $validCount, holy: $holyDeviceCount, success: ${successRate.toStringAsFixed(1)}%)';
  }
}
