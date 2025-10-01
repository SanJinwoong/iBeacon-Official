import XCTest
@testable import HolyBeaconCore

final class UuidProcessorTests: XCTestCase {
    
    func testProcessSingleHolyShunUuid() {
        let uuid = "FDA50693-A4E2-4FB1-AFCF-C6EB07647825"
        let result = UuidProcessor.processSingleUuid(uuid)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.isHolyDevice)
        XCTAssertEqual(result.deviceCategory, .shun)
        XCTAssertEqual(result.deviceType, "Holy Shun Device")
        XCTAssertEqual(result.trustLevel, 10)
        XCTAssertEqual(result.normalizedUuid, uuid)
    }
    
    func testProcessSingleHolyJinUuid() {
        let uuid = "E2C56DB5-DFFB-48D2-B060-D0F5A7100000"
        let result = UuidProcessor.processSingleUuid(uuid)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.isHolyDevice)
        XCTAssertEqual(result.deviceCategory, .jin)
        XCTAssertEqual(result.deviceType, "Holy Jin Device")
        XCTAssertEqual(result.trustLevel, 10)
    }
    
    func testProcessSingleKronosUuid() {
        let uuid = "F7826DA6-4FA2-4E98-8024-BC5B71E0893E"
        let result = UuidProcessor.processSingleUuid(uuid)
        
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.isHolyDevice)
        XCTAssertEqual(result.deviceCategory, .kronos)
        XCTAssertEqual(result.deviceType, "Kronos Blaze Device")
        XCTAssertEqual(result.trustLevel, 9)
    }
    
    func testProcessGenericUuid() {
        let uuid = "12345678-1234-5678-9012-123456789012"
        let result = UuidProcessor.processSingleUuid(uuid)
        
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.isHolyDevice)
        XCTAssertEqual(result.deviceCategory, .unknown)
        XCTAssertEqual(result.deviceType, "Generic Device")
        XCTAssertEqual(result.trustLevel, 1)
    }
    
    func testNormalizeUuidFormat() {
        let inputUuid = "fda50693a4e24fb1afcfc6eb07647825" // lowercase, no dashes
        let expectedUuid = "FDA50693-A4E2-4FB1-AFCF-C6EB07647825"
        
        let result = UuidProcessor.processSingleUuid(inputUuid, normalizeFormat: true)
        
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedUuid, expectedUuid)
        XCTAssertTrue(result.isHolyDevice)
    }
    
    func testEmptyUuid() {
        let uuid = ""
        let result = UuidProcessor.processSingleUuid(uuid)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorType, .emptyUuid)
        XCTAssertEqual(result.errorMessage, "UUID cannot be empty")
    }
    
    func testInvalidUuidFormat() {
        let uuid = "invalid-uuid-format"
        let result = UuidProcessor.processSingleUuid(uuid, validateFormat: true)
        
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorType, .invalidFormat)
        XCTAssertTrue(result.errorMessage?.contains("Invalid UUID format") == true)
    }
    
    func testProcessUuidList() {
        let uuids = [
            "FDA50693-A4E2-4FB1-AFCF-C6EB07647825", // Holy Shun
            "E2C56DB5-DFFB-48D2-B060-D0F5A7100000", // Holy Jin
            "12345678-1234-5678-9012-123456789012", // Generic
            "invalid-uuid",                          // Invalid
            "F7826DA6-4FA2-4E98-8024-BC5B71E0893E", // Kronos
        ]
        
        let result = UuidProcessor.processUuidList(uuids)
        
        XCTAssertEqual(result.totalProcessed, 5)
        XCTAssertEqual(result.validCount, 4)
        XCTAssertEqual(result.invalidCount, 1)
        XCTAssertEqual(result.holyDeviceCount, 3)
        XCTAssertEqual(result.successRate, 80.0, accuracy: 0.01)
        XCTAssertEqual(result.holyDeviceRate, 75.0, accuracy: 0.01)
    }
    
    func testUuidListWithPrioritization() {
        let uuids = [
            "12345678-1234-5678-9012-123456789012", // Generic
            "FDA50693-A4E2-4FB1-AFCF-C6EB07647825", // Holy Shun
            "E2C56DB5-DFFB-48D2-B060-D0F5A7100000", // Holy Jin
        ]
        
        let result = UuidProcessor.processUuidList(uuids, prioritizeHoly: true)
        
        XCTAssertTrue(result.validResults.first?.isHolyDevice == true)
        XCTAssertFalse(result.validResults.last?.isHolyDevice == true)
    }
    
    func testUuidFormatValidation() {
        let validUuids = [
            "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
            "12345678-1234-5678-9012-123456789012",
            "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF",
        ]
        
        for uuid in validUuids {
            XCTAssertTrue(UuidProcessor.isValidUuidFormat(uuid), "UUID \(uuid) should be valid")
        }
        
        let invalidUuids = [
            "FDA50693-A4E2-4FB1-AFCF-C6EB07647825-EXTRA",
            "FDA50693-A4E2-4FB1-AFCF",
            "not-a-uuid-at-all",
            "12345678123456789012345678901234", // no dashes
            "",
        ]
        
        for uuid in invalidUuids {
            XCTAssertFalse(UuidProcessor.isValidUuidFormat(uuid), "UUID \(uuid) should be invalid")
        }
    }
    
    func testNormalizeUuidFormatFunction() {
        let testCases: [String: String] = [
            "fda50693a4e24fb1afcfc6eb07647825": "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
            "FDA50693A4E24FB1AFCFC6EB07647825": "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
            "fda50693-a4e2-4fb1-afcf-c6eb07647825": "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
            "fda50693_a4e2_4fb1_afcf_c6eb07647825": "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
        ]
        
        for (input, expected) in testCases {
            let normalized = UuidProcessor.normalizeUuidFormat(input)
            XCTAssertEqual(normalized, expected, "Input \(input) should normalize to \(expected)")
        }
    }
    
    func testBytesToUuid() throws {
        let bytes = Data([
            0xFD, 0xA5, 0x06, 0x93, 0xA4, 0xE2, 0x4F, 0xB1,
            0xAF, 0xCF, 0xC6, 0xEB, 0x07, 0x64, 0x78, 0x25,
        ])
        
        let uuid = try UuidProcessor.bytesToUuid(bytes)
        XCTAssertEqual(uuid, "FDA50693-A4E2-4FB1-AFCF-C6EB07647825")
    }
    
    func testUuidToBytes() throws {
        let uuid = "FDA50693-A4E2-4FB1-AFCF-C6EB07647825"
        let bytes = try UuidProcessor.uuidToBytes(uuid)
        
        XCTAssertEqual(bytes.count, 16)
        XCTAssertEqual(bytes[0], 0xFD)
        XCTAssertEqual(bytes[1], 0xA5)
        XCTAssertEqual(bytes[2], 0x06)
        XCTAssertEqual(bytes[3], 0x93)
    }
    
    func testRoundTripBytesConversion() throws {
        let originalUuid = "E2C56DB5-DFFB-48D2-B060-D0F5A7100000"
        let bytes = try UuidProcessor.uuidToBytes(originalUuid)
        let convertedUuid = try UuidProcessor.bytesToUuid(bytes)
        
        XCTAssertEqual(convertedUuid, originalUuid)
    }
    
    func testInvalidBytesThrowsError() {
        let shortBytes = Data([0xFD, 0xA5]) // Only 2 bytes
        XCTAssertThrowsError(try UuidProcessor.bytesToUuid(shortBytes))
    }
    
    func testInvalidUuidThrowsError() {
        XCTAssertThrowsError(try UuidProcessor.uuidToBytes("invalid"))
        XCTAssertThrowsError(try UuidProcessor.uuidToBytes(""))
    }
    
    func testEmptyUuidList() {
        let result = UuidProcessor.processUuidList([])
        
        XCTAssertEqual(result.totalProcessed, 0)
        XCTAssertEqual(result.validCount, 0)
        XCTAssertEqual(result.holyDeviceCount, 0)
    }
}