import Flutter
import UIKit
import CoreBluetooth
import CoreLocation

public class HolyBeaconSdkPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    
    private var centralManager: CBCentralManager?
    private var locationManager: CLLocationManager?
    private var isScanning = false
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "holy_beacon_sdk", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "holy_beacon_sdk/events", binaryMessenger: registrar.messenger())
        let instance = HolyBeaconSdkPlugin()
        
        instance.channel = channel
        instance.eventChannel = eventChannel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
        case "isBluetoothEnabled":
            isBluetoothEnabled(result: result)
        case "requestBluetoothEnable":
            requestBluetoothEnable(result: result)
        case "startScan":
            startScan(result: result)
        case "stopScan":
            stopScan(result: result)
        case "setScanParameters":
            setScanParameters(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(result: @escaping FlutterResult) {
        setupManagers()
        result(nil)
    }
    
    private func setupManagers() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        locationManager = CLLocationManager()
        locationManager?.delegate = self
    }
    
    private func isBluetoothEnabled(result: @escaping FlutterResult) {
        guard let centralManager = centralManager else {
            result(false)
            return
        }
        result(centralManager.state == .poweredOn)
    }
    
    private func requestBluetoothEnable(result: @escaping FlutterResult) {
        // On iOS, we cannot programmatically enable Bluetooth
        // We can only check the current state
        result(centralManager?.state == .poweredOn)
    }
    
    private func startScan(result: @escaping FlutterResult) {
        guard let centralManager = centralManager else {
            result(FlutterError(code: "BLUETOOTH_NOT_INITIALIZED", 
                              message: "Bluetooth manager not initialized", 
                              details: nil))
            return
        }
        
        guard centralManager.state == .poweredOn else {
            result(FlutterError(code: "BLUETOOTH_DISABLED", 
                              message: "Bluetooth is not powered on", 
                              details: nil))
            return
        }
        
        guard !isScanning else {
            result("ALREADY_SCANNING")
            return
        }
        
        // Request location permission if needed
        if locationManager?.authorizationStatus == .notDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
        
        // Start scanning for all peripherals
        centralManager.scanForPeripherals(withServices: nil, 
                                        options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
        result("SCAN_STARTED")
    }
    
    private func stopScan(result: @escaping FlutterResult) {
        guard isScanning else {
            result("NOT_SCANNING")
            return
        }
        
        centralManager?.stopScan()
        isScanning = false
        result("SCAN_STOPPED")
    }
    
    private func setScanParameters(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // iOS doesn't have as many scan parameter options as Android
        // This method is here for consistency
        result(nil)
    }
    
    private func handlePeripheral(_ peripheral: CBPeripheral, 
                                advertisementData: [String: Any], 
                                rssi: NSNumber) {
        var deviceData: [String: Any] = [:]
        
        deviceData["deviceId"] = peripheral.identifier.uuidString
        deviceData["name"] = peripheral.name ?? ""
        deviceData["rssi"] = rssi.intValue
        deviceData["lastSeen"] = Int(Date().timeIntervalSince1970 * 1000)
        
        // Check for iBeacon data in advertisement
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            if let beaconData = parseIBeacon(data: manufacturerData, deviceName: peripheral.name ?? "") {
                deviceData.merge(beaconData) { _, new in new }
            }
        }
        
        // Set defaults if not parsed as beacon
        if deviceData["uuid"] == nil {
            deviceData["uuid"] = ""
            deviceData["major"] = 0
            deviceData["minor"] = 0
            deviceData["protocol"] = "bleDevice"
            deviceData["verified"] = isHolyDevice(deviceName: peripheral.name ?? "")
        }
        
        eventSink?(deviceData)
    }
    
    private func parseIBeacon(data: Data, deviceName: String) -> [String: Any]? {
        guard data.count >= 25 else { return nil }
        
        let bytes = [UInt8](data)
        
        // Check for Apple Company ID (0x004C) and iBeacon format
        guard bytes[0] == 0x4C && bytes[1] == 0x00 && 
              bytes[2] == 0x02 && bytes[3] == 0x15 else { return nil }
        
        // Extract UUID (16 bytes)
        let uuidBytes = Array(bytes[4..<20])
        let uuid = formatUuid(bytes: uuidBytes)
        
        // Extract Major (2 bytes)
        let major = (Int(bytes[20]) << 8) | Int(bytes[21])
        
        // Extract Minor (2 bytes)  
        let minor = (Int(bytes[22]) << 8) | Int(bytes[23])
        
        // Extract TX Power (1 byte, signed)
        let txPower = Int8(bitPattern: bytes[24])
        
        return [
            "uuid": uuid,
            "major": major,
            "minor": minor,
            "protocol": "ibeacon",
            "verified": true
        ]
    }
    
    private func formatUuid(bytes: [UInt8]) -> String {
        let hex = bytes.map { String(format: "%02X", $0) }.joined()
        return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20))"
    }
    
    private func isHolyDevice(deviceName: String) -> Bool {
        let name = deviceName.lowercased()
        return name.contains("holy") || name.contains("kronos") || name.contains("blaze")
    }
}

// MARK: - CBCentralManagerDelegate
extension HolyBeaconSdkPlugin: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Handle Bluetooth state changes
        switch central.state {
        case .poweredOn:
            break
        case .poweredOff:
            if isScanning {
                isScanning = false
                eventSink?(FlutterError(code: "BLUETOOTH_POWERED_OFF",
                                      message: "Bluetooth was powered off during scanning",
                                      details: nil))
            }
        default:
            break
        }
    }
    
    public func centralManager(_ central: CBCentralManager, 
                             didDiscover peripheral: CBPeripheral, 
                             advertisementData: [String : Any], 
                             rssi RSSI: NSNumber) {
        handlePeripheral(peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
}

// MARK: - CLLocationManagerDelegate
extension HolyBeaconSdkPlugin: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, 
                              didChangeAuthorization status: CLAuthorizationStatus) {
        // Handle location permission changes
    }
}

// MARK: - FlutterStreamHandler
extension HolyBeaconSdkPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, 
                        eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}