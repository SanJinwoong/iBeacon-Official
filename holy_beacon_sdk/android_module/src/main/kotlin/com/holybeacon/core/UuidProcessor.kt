package com.holybeacon.core

/**
 * Core UUID processing functionality for Holy Beacon SDK
 * 
 * This class provides the fundamental UUID processing logic that can be
 * integrated into larger Android systems.
 * 
 * Key Features:
 * - Process single UUIDs or lists of UUIDs
 * - Validation and normalization
 * - Holy device detection and verification
 * - Format conversion and error handling
 * - Scalable for integration into larger systems
 */
object UuidProcessor {
    
    // Known UUIDs for Holy devices - the core business logic
    private val HOLY_SHUN_UUIDS = listOf(
        "FDA50693-A4E2-4FB1-AFCF-C6EB07647825"
    )
    
    private val HOLY_JIN_UUIDS = listOf(
        "E2C56DB5-DFFB-48D2-B060-D0F5A7100000"
    )
    
    private val KRONOS_UUIDS = listOf(
        "F7826DA6-4FA2-4E98-8024-BC5B71E0893E"
    )
    
    /**
     * Combined list of all known Holy device UUIDs
     */
    val KNOWN_HOLY_UUIDS = HOLY_SHUN_UUIDS + HOLY_JIN_UUIDS + KRONOS_UUIDS
    
    /**
     * Process a single UUID with validation, normalization, and Holy device detection
     * 
     * @param uuid The UUID string to process
     * @param validateFormat Whether to perform strict format validation
     * @param normalizeFormat Whether to normalize the UUID format
     * @return UuidProcessingResult with processing outcome
     * 
     * Example:
     * ```kotlin
     * val result = UuidProcessor.processSingleUuid(
     *     "fda50693-a4e2-4fb1-afcf-c6eb07647825",
     *     validateFormat = true,
     *     normalizeFormat = true
     * )
     * 
     * if (result.isValid) {
     *     println("UUID: ${result.normalizedUuid}")
     *     println("Is Holy device: ${result.isHolyDevice}")
     *     println("Device category: ${result.deviceCategory}")
     * }
     * ```
     */
    @JvmStatic
    @JvmOverloads
    fun processSingleUuid(
        uuid: String,
        validateFormat: Boolean = true,
        normalizeFormat: Boolean = true
    ): UuidProcessingResult {
        return try {
            // Handle null or empty UUID
            if (uuid.isEmpty()) {
                return UuidProcessingResult.error(
                    originalUuid = uuid,
                    errorType = UuidErrorType.EMPTY_UUID,
                    errorMessage = "UUID cannot be empty"
                )
            }

            // Normalize format first
            var processedUuid = uuid
            if (normalizeFormat) {
                processedUuid = normalizeUuidFormat(uuid)
            }

            // Validate format if requested
            if (validateFormat && !isValidUuidFormat(processedUuid)) {
                return UuidProcessingResult.error(
                    originalUuid = uuid,
                    errorType = UuidErrorType.INVALID_FORMAT,
                    errorMessage = "Invalid UUID format: $uuid"
                )
            }

            // Detect Holy device category
            val deviceInfo = detectHolyDevice(processedUuid)

            UuidProcessingResult.success(
                originalUuid = uuid,
                normalizedUuid = processedUuid,
                isHolyDevice = deviceInfo.isHoly,
                deviceCategory = deviceInfo.category,
                deviceType = deviceInfo.type,
                trustLevel = deviceInfo.trustLevel
            )
        } catch (e: Exception) {
            UuidProcessingResult.error(
                originalUuid = uuid,
                errorType = UuidErrorType.PROCESSING_ERROR,
                errorMessage = "Processing error: ${e.message}"
            )
        }
    }

    /**
     * Process a list of UUIDs with comprehensive filtering and categorization
     * 
     * @param uuids List of UUID strings to process
     * @param filterInvalid Whether to exclude invalid UUIDs from results
     * @param prioritizeHoly Whether to sort Holy devices first
     * @param validateFormat Whether to perform strict format validation
     * @param normalizeFormat Whether to normalize UUID formats
     * @return UuidListProcessingResult with categorized results
     * 
     * Example:
     * ```kotlin
     * val uuids = listOf(
     *     "FDA50693-A4E2-4FB1-AFCF-C6EB07647825", // Holy Shun
     *     "invalid-uuid",
     *     "E2C56DB5-DFFB-48D2-B060-D0F5A7100000"  // Holy Jin
     * )
     * 
     * val result = UuidProcessor.processUuidList(
     *     uuids,
     *     filterInvalid = true,
     *     prioritizeHoly = true
     * )
     * 
     * println("Total processed: ${result.totalProcessed}")
     * println("Holy devices: ${result.holyDeviceCount}")
     * println("Valid UUIDs: ${result.validResults.size}")
     * ```
     */
    @JvmStatic
    @JvmOverloads
    fun processUuidList(
        uuids: List<String>,
        filterInvalid: Boolean = false,
        prioritizeHoly: Boolean = false,
        validateFormat: Boolean = true,
        normalizeFormat: Boolean = true
    ): UuidListProcessingResult {
        if (uuids.isEmpty()) {
            return UuidListProcessingResult.empty()
        }

        val allResults = mutableListOf<UuidProcessingResult>()
        val validResults = mutableListOf<UuidProcessingResult>()
        val invalidResults = mutableListOf<UuidProcessingResult>()
        val holyResults = mutableListOf<UuidProcessingResult>()

        // Process each UUID
        for (uuid in uuids) {
            val result = processSingleUuid(uuid, validateFormat, normalizeFormat)
            allResults.add(result)

            if (result.isValid) {
                validResults.add(result)
                if (result.isHolyDevice) {
                    holyResults.add(result)
                }
            } else {
                invalidResults.add(result)
            }
        }

        // Sort results if prioritization is requested
        if (prioritizeHoly && validResults.isNotEmpty()) {
            validResults.sortWith { a, b ->
                // Holy devices first, then by trust level, then alphabetical
                when {
                    a.isHolyDevice && !b.isHolyDevice -> -1
                    !a.isHolyDevice && b.isHolyDevice -> 1
                    else -> {
                        val trustComparison = b.trustLevel.compareTo(a.trustLevel)
                        if (trustComparison != 0) trustComparison
                        else a.normalizedUuid.compareTo(b.normalizedUuid)
                    }
                }
            }
        }

        return UuidListProcessingResult(
            totalProcessed = uuids.size,
            allResults = allResults,
            validResults = if (filterInvalid) validResults else allResults,
            invalidResults = invalidResults,
            holyResults = holyResults
        )
    }

    /**
     * Normalize UUID format to standard 8-4-4-4-12 format with uppercase
     * 
     * @param uuid The UUID to normalize
     * @return Normalized UUID string
     * 
     * Example:
     * ```kotlin
     * val normalized = UuidProcessor.normalizeUuidFormat("fda50693a4e24fb1afcfc6eb07647825")
     * println(normalized) // FDA50693-A4E2-4FB1-AFCF-C6EB07647825
     * ```
     */
    @JvmStatic
    fun normalizeUuidFormat(uuid: String): String {
        if (uuid.isEmpty()) return uuid

        // Remove all non-hex characters and convert to uppercase
        val cleanUuid = uuid.replace(Regex("[^0-9a-fA-F]"), "").uppercase()

        // Add dashes if we have exactly 32 hex characters
        return if (cleanUuid.length == 32) {
            "${cleanUuid.substring(0, 8)}-${cleanUuid.substring(8, 12)}-${cleanUuid.substring(12, 16)}-${cleanUuid.substring(16, 20)}-${cleanUuid.substring(20, 32)}"
        } else {
            uuid // Return original if not standard length
        }
    }

    /**
     * Validate UUID format according to RFC 4122
     * 
     * @param uuid The UUID to validate
     * @return True if the UUID format is valid
     * 
     * Example:
     * ```kotlin
     * val isValid = UuidProcessor.isValidUuidFormat("FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
     * println(isValid) // true
     * ```
     */
    @JvmStatic
    fun isValidUuidFormat(uuid: String): Boolean {
        if (uuid.isEmpty()) return false
        
        val pattern = Regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$")
        return pattern.matches(uuid)
    }

    /**
     * Convert byte array to UUID string
     * 
     * @param bytes The byte array (must be at least 16 bytes)
     * @return UUID string
     * 
     * Example:
     * ```kotlin
     * val bytes = byteArrayOf(0xFD.toByte(), 0xA5.toByte(), 0x06.toByte(), 0x93.toByte(), ...)
     * val uuid = UuidProcessor.bytesToUuid(bytes)
     * ```
     */
    @JvmStatic
    fun bytesToUuid(bytes: ByteArray): String {
        if (bytes.size < 16) {
            throw IllegalArgumentException("UUID bytes must be at least 16 bytes long")
        }

        val hex = bytes.take(16)
            .map { "%02X".format(it) }
            .joinToString("")

        return "${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}"
    }

    /**
     * Convert UUID string to byte array
     * 
     * @param uuid The UUID string
     * @return Byte array representation
     * 
     * Example:
     * ```kotlin
     * val bytes = UuidProcessor.uuidToBytes("FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
     * ```
     */
    @JvmStatic
    fun uuidToBytes(uuid: String): ByteArray {
        val cleanUuid = uuid.replace("-", "")
        if (cleanUuid.length != 32) {
            throw IllegalArgumentException("UUID must be 32 hex characters")
        }

        val bytes = ByteArray(16)
        for (i in 0 until 16) {
            val hex = cleanUuid.substring(i * 2, i * 2 + 2)
            bytes[i] = hex.toInt(16).toByte()
        }
        return bytes
    }

    /**
     * Internal method to detect Holy device information
     */
    private fun detectHolyDevice(normalizedUuid: String): HolyDeviceInfo {
        val upperUuid = normalizedUuid.uppercase()

        return when {
            HOLY_SHUN_UUIDS.any { it.uppercase() == upperUuid } -> {
                HolyDeviceInfo(
                    isHoly = true,
                    category = HolyDeviceCategory.SHUN,
                    type = "Holy Shun Device",
                    trustLevel = 10
                )
            }
            HOLY_JIN_UUIDS.any { it.uppercase() == upperUuid } -> {
                HolyDeviceInfo(
                    isHoly = true,
                    category = HolyDeviceCategory.JIN,
                    type = "Holy Jin Device",
                    trustLevel = 10
                )
            }
            KRONOS_UUIDS.any { it.uppercase() == upperUuid } -> {
                HolyDeviceInfo(
                    isHoly = true,
                    category = HolyDeviceCategory.KRONOS,
                    type = "Kronos Blaze Device",
                    trustLevel = 9
                )
            }
            else -> {
                HolyDeviceInfo(
                    isHoly = false,
                    category = HolyDeviceCategory.UNKNOWN,
                    type = "Generic Device",
                    trustLevel = 1
                )
            }
        }
    }
}

/**
 * Internal class for Holy device information
 */
private data class HolyDeviceInfo(
    val isHoly: Boolean,
    val category: HolyDeviceCategory,
    val type: String,
    val trustLevel: Int
)