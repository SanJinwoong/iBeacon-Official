import Foundation

/// Categories of Holy devices
@objc public enum HolyDeviceCategory: Int, CaseIterable {
    case shun = 0
    case jin = 1
    case kronos = 2
    case unknown = 3
    
    public var name: String {
        switch self {
        case .shun: return "shun"
        case .jin: return "jin"
        case .kronos: return "kronos"
        case .unknown: return "unknown"
        }
    }
}

/// Error types for UUID processing
@objc public enum UuidErrorType: Int, CaseIterable {
    case emptyUuid = 0
    case invalidFormat = 1
    case processingError = 2
    
    public var name: String {
        switch self {
        case .emptyUuid: return "emptyUuid"
        case .invalidFormat: return "invalidFormat"
        case .processingError: return "processingError"
        }
    }
}

/// Result of processing a single UUID
@objc public class UuidProcessingResult: NSObject {
    @objc public let originalUuid: String
    @objc public let normalizedUuid: String
    @objc public let isValid: Bool
    @objc public let isHolyDevice: Bool
    @objc public let deviceCategory: HolyDeviceCategory
    @objc public let deviceType: String
    @objc public let trustLevel: Int
    @objc public let errorType: UuidErrorType
    @objc public let errorMessage: String?
    
    private init(
        originalUuid: String,
        normalizedUuid: String,
        isValid: Bool,
        isHolyDevice: Bool,
        deviceCategory: HolyDeviceCategory,
        deviceType: String,
        trustLevel: Int,
        errorType: UuidErrorType = .processingError,
        errorMessage: String? = nil
    ) {
        self.originalUuid = originalUuid
        self.normalizedUuid = normalizedUuid
        self.isValid = isValid
        self.isHolyDevice = isHolyDevice
        self.deviceCategory = deviceCategory
        self.deviceType = deviceType
        self.trustLevel = trustLevel
        self.errorType = errorType
        self.errorMessage = errorMessage
    }
    
    @objc public static func success(
        originalUuid: String,
        normalizedUuid: String,
        isHolyDevice: Bool,
        deviceCategory: HolyDeviceCategory,
        deviceType: String,
        trustLevel: Int
    ) -> UuidProcessingResult {
        return UuidProcessingResult(
            originalUuid: originalUuid,
            normalizedUuid: normalizedUuid,
            isValid: true,
            isHolyDevice: isHolyDevice,
            deviceCategory: deviceCategory,
            deviceType: deviceType,
            trustLevel: trustLevel
        )
    }
    
    @objc public static func error(
        originalUuid: String,
        errorType: UuidErrorType,
        errorMessage: String
    ) -> UuidProcessingResult {
        return UuidProcessingResult(
            originalUuid: originalUuid,
            normalizedUuid: originalUuid,
            isValid: false,
            isHolyDevice: false,
            deviceCategory: .unknown,
            deviceType: "Error",
            trustLevel: 0,
            errorType: errorType,
            errorMessage: errorMessage
        )
    }
    
    public override var description: String {
        if isValid {
            return "UuidProcessingResult(uuid: \(normalizedUuid), holy: \(isHolyDevice), category: \(deviceCategory.name), trust: \(trustLevel))"
        } else {
            return "UuidProcessingResult(error: \(errorType.name), message: \(errorMessage ?? "No message"))"
        }
    }
}

/// Result of processing a list of UUIDs
@objc public class UuidListProcessingResult: NSObject {
    @objc public let totalProcessed: Int
    @objc public let allResults: [UuidProcessingResult]
    @objc public let validResults: [UuidProcessingResult]
    @objc public let invalidResults: [UuidProcessingResult]
    @objc public let holyResults: [UuidProcessingResult]
    
    public init(
        totalProcessed: Int,
        allResults: [UuidProcessingResult],
        validResults: [UuidProcessingResult],
        invalidResults: [UuidProcessingResult],
        holyResults: [UuidProcessingResult]
    ) {
        self.totalProcessed = totalProcessed
        self.allResults = allResults
        self.validResults = validResults
        self.invalidResults = invalidResults
        self.holyResults = holyResults
    }
    
    @objc public static func empty() -> UuidListProcessingResult {
        return UuidListProcessingResult(
            totalProcessed: 0,
            allResults: [],
            validResults: [],
            invalidResults: [],
            holyResults: []
        )
    }
    
    /// Get count of valid UUIDs
    @objc public var validCount: Int { validResults.count }
    
    /// Get count of invalid UUIDs
    @objc public var invalidCount: Int { invalidResults.count }
    
    /// Get count of Holy devices
    @objc public var holyDeviceCount: Int { holyResults.count }
    
    /// Get success rate as percentage
    @objc public var successRate: Double {
        totalProcessed > 0 ? (Double(validCount) / Double(totalProcessed)) * 100 : 0.0
    }
    
    /// Get Holy device rate as percentage
    @objc public var holyDeviceRate: Double {
        validCount > 0 ? (Double(holyDeviceCount) / Double(validCount)) * 100 : 0.0
    }
    
    public override var description: String {
        return "UuidListProcessingResult(total: \(totalProcessed), valid: \(validCount), holy: \(holyDeviceCount), success: \(String(format: "%.1f", successRate))%)"
    }
}