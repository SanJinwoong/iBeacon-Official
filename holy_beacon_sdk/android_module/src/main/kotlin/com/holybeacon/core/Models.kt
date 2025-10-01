package com.holybeacon.core

/**
 * Categories of Holy devices
 */
enum class HolyDeviceCategory {
    SHUN,
    JIN,
    KRONOS,
    UNKNOWN
}

/**
 * Error types for UUID processing
 */
enum class UuidErrorType {
    EMPTY_UUID,
    INVALID_FORMAT,
    PROCESSING_ERROR
}

/**
 * Result of processing a single UUID
 */
data class UuidProcessingResult(
    val originalUuid: String,
    val normalizedUuid: String,
    val isValid: Boolean,
    val isHolyDevice: Boolean,
    val deviceCategory: HolyDeviceCategory,
    val deviceType: String,
    val trustLevel: Int,
    val errorType: UuidErrorType? = null,
    val errorMessage: String? = null
) {
    companion object {
        @JvmStatic
        fun success(
            originalUuid: String,
            normalizedUuid: String,
            isHolyDevice: Boolean,
            deviceCategory: HolyDeviceCategory,
            deviceType: String,
            trustLevel: Int
        ): UuidProcessingResult {
            return UuidProcessingResult(
                originalUuid = originalUuid,
                normalizedUuid = normalizedUuid,
                isValid = true,
                isHolyDevice = isHolyDevice,
                deviceCategory = deviceCategory,
                deviceType = deviceType,
                trustLevel = trustLevel
            )
        }

        @JvmStatic
        fun error(
            originalUuid: String,
            errorType: UuidErrorType,
            errorMessage: String
        ): UuidProcessingResult {
            return UuidProcessingResult(
                originalUuid = originalUuid,
                normalizedUuid = originalUuid,
                isValid = false,
                isHolyDevice = false,
                deviceCategory = HolyDeviceCategory.UNKNOWN,
                deviceType = "Error",
                trustLevel = 0,
                errorType = errorType,
                errorMessage = errorMessage
            )
        }
    }

    override fun toString(): String {
        return if (isValid) {
            "UuidProcessingResult(uuid: $normalizedUuid, holy: $isHolyDevice, category: $deviceCategory, trust: $trustLevel)"
        } else {
            "UuidProcessingResult(error: $errorType, message: $errorMessage)"
        }
    }
}

/**
 * Result of processing a list of UUIDs
 */
data class UuidListProcessingResult(
    val totalProcessed: Int,
    val allResults: List<UuidProcessingResult>,
    val validResults: List<UuidProcessingResult>,
    val invalidResults: List<UuidProcessingResult>,
    val holyResults: List<UuidProcessingResult>
) {
    companion object {
        @JvmStatic
        fun empty(): UuidListProcessingResult {
            return UuidListProcessingResult(
                totalProcessed = 0,
                allResults = emptyList(),
                validResults = emptyList(),
                invalidResults = emptyList(),
                holyResults = emptyList()
            )
        }
    }

    /**
     * Get count of valid UUIDs
     */
    val validCount: Int get() = validResults.size

    /**
     * Get count of invalid UUIDs
     */
    val invalidCount: Int get() = invalidResults.size

    /**
     * Get count of Holy devices
     */
    val holyDeviceCount: Int get() = holyResults.size

    /**
     * Get success rate as percentage
     */
    val successRate: Double get() = if (totalProcessed > 0) (validCount.toDouble() / totalProcessed) * 100 else 0.0

    /**
     * Get Holy device rate as percentage
     */
    val holyDeviceRate: Double get() = if (validCount > 0) (holyDeviceCount.toDouble() / validCount) * 100 else 0.0

    override fun toString(): String {
        return "UuidListProcessingResult(total: $totalProcessed, valid: $validCount, holy: $holyDeviceCount, success: ${"%.1f".format(successRate)}%)"
    }
}