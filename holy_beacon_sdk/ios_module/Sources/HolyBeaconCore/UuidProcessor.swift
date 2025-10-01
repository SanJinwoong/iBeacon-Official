import Foundation

/// Core UUID processing functionality for Holy Beacon SDK
///
/// This class provides the fundamental UUID processing logic that can be
/// integrated into larger iOS/macOS systems.
///
/// Key Features:
/// - Process single UUIDs or lists of UUIDs
/// - Validation and normalization
/// - Holy device detection and verification
/// - Format conversion and error handling
/// - Scalable for integration into larger systems
@objc public class UuidProcessor: NSObject {
    
    // Known UUIDs for Holy devices - the core business logic
    private static let holyShunUuids = [
        "FDA50693-A4E2-4FB1-AFCF-C6EB07647825"
    ]
    
    private static let holyJinUuids = [
        "E2C56DB5-DFFB-48D2-B060-D0F5A7100000"
    ]
    
    private static let kronosUuids = [
        "F7826DA6-4FA2-4E98-8024-BC5B71E0893E"
    ]
    
    /// Combined list of all known Holy device UUIDs
    @objc public static let knownHolyUuids = holyShunUuids + holyJinUuids + kronosUuids
    
    /// Process a single UUID with validation, normalization, and Holy device detection
    ///
    /// - Parameters:
    ///   - uuid: The UUID string to process
    ///   - validateFormat: Whether to perform strict format validation
    ///   - normalizeFormat: Whether to normalize the UUID format
    /// - Returns: UuidProcessingResult with processing outcome
    ///
    /// Example:
    /// ```swift
    /// let result = UuidProcessor.processSingleUuid(
    ///     "fda50693-a4e2-4fb1-afcf-c6eb07647825",
    ///     validateFormat: true,
    ///     normalizeFormat: true
    /// )
    ///
    /// if result.isValid {
    ///     print("UUID: \(result.normalizedUuid)")
    ///     print("Is Holy device: \(result.isHolyDevice)")
    ///     print("Device category: \(result.deviceCategory)")
    /// }
    /// ```
    @objc public static func processSingleUuid(
        _ uuid: String,
        validateFormat: Bool = true,
        normalizeFormat: Bool = true
    ) -> UuidProcessingResult {
        do {
            // Handle empty UUID
            if uuid.isEmpty {
                return UuidProcessingResult.error(
                    originalUuid: uuid,
                    errorType: .emptyUuid,
                    errorMessage: "UUID cannot be empty"
                )
            }

            // Normalize format first
            var processedUuid = uuid
            if normalizeFormat {
                processedUuid = normalizeUuidFormat(uuid)
            }

            // Validate format if requested
            if validateFormat && !isValidUuidFormat(processedUuid) {
                return UuidProcessingResult.error(
                    originalUuid: uuid,
                    errorType: .invalidFormat,
                    errorMessage: "Invalid UUID format: \(uuid)"
                )
            }

            // Detect Holy device category
            let deviceInfo = detectHolyDevice(processedUuid)

            return UuidProcessingResult.success(
                originalUuid: uuid,
                normalizedUuid: processedUuid,
                isHolyDevice: deviceInfo.isHoly,
                deviceCategory: deviceInfo.category,
                deviceType: deviceInfo.type,
                trustLevel: deviceInfo.trustLevel
            )
        } catch {
            return UuidProcessingResult.error(
                originalUuid: uuid,
                errorType: .processingError,
                errorMessage: "Processing error: \(error.localizedDescription)"
            )
        }
    }

    /// Process a list of UUIDs with comprehensive filtering and categorization
    ///
    /// - Parameters:
    ///   - uuids: List of UUID strings to process
    ///   - filterInvalid: Whether to exclude invalid UUIDs from results
    ///   - prioritizeHoly: Whether to sort Holy devices first
    ///   - validateFormat: Whether to perform strict format validation
    ///   - normalizeFormat: Whether to normalize UUID formats
    /// - Returns: UuidListProcessingResult with categorized results
    ///
    /// Example:
    /// ```swift
    /// let uuids = [
    ///     "FDA50693-A4E2-4FB1-AFCF-C6EB07647825", // Holy Shun
    ///     "invalid-uuid",
    ///     "E2C56DB5-DFFB-48D2-B060-D0F5A7100000"  // Holy Jin
    /// ]
    ///
    /// let result = UuidProcessor.processUuidList(
    ///     uuids,
    ///     filterInvalid: true,
    ///     prioritizeHoly: true
    /// )
    ///
    /// print("Total processed: \(result.totalProcessed)")
    /// print("Holy devices: \(result.holyDeviceCount)")
    /// print("Valid UUIDs: \(result.validResults.count)")
    /// ```
    @objc public static func processUuidList(
        _ uuids: [String],
        filterInvalid: Bool = false,
        prioritizeHoly: Bool = false,
        validateFormat: Bool = true,
        normalizeFormat: Bool = true
    ) -> UuidListProcessingResult {
        if uuids.isEmpty {
            return UuidListProcessingResult.empty()
        }

        var allResults: [UuidProcessingResult] = []
        var validResults: [UuidProcessingResult] = []
        var invalidResults: [UuidProcessingResult] = []
        var holyResults: [UuidProcessingResult] = []

        // Process each UUID
        for uuid in uuids {
            let result = processSingleUuid(uuid, validateFormat: validateFormat, normalizeFormat: normalizeFormat)
            allResults.append(result)

            if result.isValid {
                validResults.append(result)
                if result.isHolyDevice {
                    holyResults.append(result)
                }
            } else {
                invalidResults.append(result)
            }
        }

        // Sort results if prioritization is requested
        if prioritizeHoly && !validResults.isEmpty {
            validResults.sort { a, b in
                // Holy devices first, then by trust level, then alphabetical
                if a.isHolyDevice && !b.isHolyDevice { return true }
                if !a.isHolyDevice && b.isHolyDevice { return false }
                
                if a.trustLevel != b.trustLevel {
                    return a.trustLevel > b.trustLevel
                }
                
                return a.normalizedUuid < b.normalizedUuid
            }
        }

        return UuidListProcessingResult(
            totalProcessed: uuids.count,
            allResults: allResults,
            validResults: filterInvalid ? validResults : allResults,
            invalidResults: invalidResults,
            holyResults: holyResults
        )
    }

    /// Normalize UUID format to standard 8-4-4-4-12 format with uppercase
    ///
    /// - Parameter uuid: The UUID to normalize
    /// - Returns: Normalized UUID string
    ///
    /// Example:
    /// ```swift
    /// let normalized = UuidProcessor.normalizeUuidFormat("fda50693a4e24fb1afcfc6eb07647825")
    /// print(normalized) // FDA50693-A4E2-4FB1-AFCF-C6EB07647825
    /// ```
    @objc public static func normalizeUuidFormat(_ uuid: String) -> String {
        if uuid.isEmpty { return uuid }

        // Remove all non-hex characters and convert to uppercase
        let cleanUuid = uuid.replacingOccurrences(of: #"[^0-9a-fA-F]"#, with: "", options: .regularExpression).uppercased()

        // Add dashes if we have exactly 32 hex characters
        if cleanUuid.count == 32 {
            let startIndex = cleanUuid.startIndex
            let part1 = cleanUuid[startIndex..<cleanUuid.index(startIndex, offsetBy: 8)]
            let part2 = cleanUuid[cleanUuid.index(startIndex, offsetBy: 8)..<cleanUuid.index(startIndex, offsetBy: 12)]
            let part3 = cleanUuid[cleanUuid.index(startIndex, offsetBy: 12)..<cleanUuid.index(startIndex, offsetBy: 16)]
            let part4 = cleanUuid[cleanUuid.index(startIndex, offsetBy: 16)..<cleanUuid.index(startIndex, offsetBy: 20)]
            let part5 = cleanUuid[cleanUuid.index(startIndex, offsetBy: 20)...]
            
            return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
        } else {
            return uuid // Return original if not standard length
        }
    }

    /// Validate UUID format according to RFC 4122
    ///
    /// - Parameter uuid: The UUID to validate
    /// - Returns: True if the UUID format is valid
    ///
    /// Example:
    /// ```swift
    /// let isValid = UuidProcessor.isValidUuidFormat("FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
    /// print(isValid) // true
    /// ```
    @objc public static func isValidUuidFormat(_ uuid: String) -> Bool {
        if uuid.isEmpty { return false }
        
        let pattern = #"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"#
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: uuid.utf16.count)
        return regex?.firstMatch(in: uuid, options: [], range: range) != nil
    }

    /// Convert byte array to UUID string
    ///
    /// - Parameter bytes: The byte array (must be at least 16 bytes)
    /// - Returns: UUID string
    /// - Throws: Error if bytes array is too short
    ///
    /// Example:
    /// ```swift
    /// let bytes = Data([0xFD, 0xA5, 0x06, 0x93, ...])
    /// let uuid = try UuidProcessor.bytesToUuid(bytes)
    /// ```
    @objc public static func bytesToUuid(_ bytes: Data) throws -> String {
        if bytes.count < 16 {
            throw UuidProcessorError.insufficientBytes("UUID bytes must be at least 16 bytes long")
        }

        let uuidBytes = bytes.prefix(16)
        let hex = uuidBytes.map { String(format: "%02X", $0) }.joined()

        let startIndex = hex.startIndex
        let part1 = hex[startIndex..<hex.index(startIndex, offsetBy: 8)]
        let part2 = hex[hex.index(startIndex, offsetBy: 8)..<hex.index(startIndex, offsetBy: 12)]
        let part3 = hex[hex.index(startIndex, offsetBy: 12)..<hex.index(startIndex, offsetBy: 16)]
        let part4 = hex[hex.index(startIndex, offsetBy: 16)..<hex.index(startIndex, offsetBy: 20)]
        let part5 = hex[hex.index(startIndex, offsetBy: 20)...]
        
        return "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
    }

    /// Convert UUID string to byte array
    ///
    /// - Parameter uuid: The UUID string
    /// - Returns: Data representation
    /// - Throws: Error if UUID format is invalid
    ///
    /// Example:
    /// ```swift
    /// let bytes = try UuidProcessor.uuidToBytes("FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
    /// ```
    @objc public static func uuidToBytes(_ uuid: String) throws -> Data {
        let cleanUuid = uuid.replacingOccurrences(of: "-", with: "")
        if cleanUuid.count != 32 {
            throw UuidProcessorError.invalidUuid("UUID must be 32 hex characters")
        }

        var bytes = Data()
        var index = cleanUuid.startIndex
        
        for _ in 0..<16 {
            let nextIndex = cleanUuid.index(index, offsetBy: 2)
            let hexString = String(cleanUuid[index..<nextIndex])
            
            guard let byte = UInt8(hexString, radix: 16) else {
                throw UuidProcessorError.invalidUuid("Invalid hex characters in UUID")
            }
            
            bytes.append(byte)
            index = nextIndex
        }
        
        return bytes
    }

    // MARK: - Private Methods

    /// Internal method to detect Holy device information
    private static func detectHolyDevice(_ normalizedUuid: String) -> HolyDeviceInfo {
        let upperUuid = normalizedUuid.uppercased()

        if holyShunUuids.contains(where: { $0.uppercased() == upperUuid }) {
            return HolyDeviceInfo(
                isHoly: true,
                category: .shun,
                type: "Holy Shun Device",
                trustLevel: 10
            )
        }

        if holyJinUuids.contains(where: { $0.uppercased() == upperUuid }) {
            return HolyDeviceInfo(
                isHoly: true,
                category: .jin,
                type: "Holy Jin Device",
                trustLevel: 10
            )
        }

        if kronosUuids.contains(where: { $0.uppercased() == upperUuid }) {
            return HolyDeviceInfo(
                isHoly: true,
                category: .kronos,
                type: "Kronos Blaze Device",
                trustLevel: 9
            )
        }

        return HolyDeviceInfo(
            isHoly: false,
            category: .unknown,
            type: "Generic Device",
            trustLevel: 1
        )
    }
}

/// Internal struct for Holy device information
private struct HolyDeviceInfo {
    let isHoly: Bool
    let category: HolyDeviceCategory
    let type: String
    let trustLevel: Int
}

/// Custom errors for UuidProcessor
public enum UuidProcessorError: LocalizedError {
    case insufficientBytes(String)
    case invalidUuid(String)
    
    public var errorDescription: String? {
        switch self {
        case .insufficientBytes(let message), .invalidUuid(let message):
            return message
        }
    }
}