package com.holybeacon.sdk

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class HolyBeaconSdkPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel : MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothLeScanner: BluetoothLeScanner? = null
    private var isScanning = false
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null

    companion object {
        private const val TAG = "HolyBeaconSdkPlugin"
        private const val METHOD_CHANNEL = "holy_beacon_sdk"
        private const val EVENT_CHANNEL = "holy_beacon_sdk/events"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, METHOD_CHANNEL)
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)
        
        initializeBluetooth()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "isBluetoothEnabled" -> isBluetoothEnabled(result)
            "requestBluetoothEnable" -> requestBluetoothEnable(result)
            "startScan" -> startScan(result)
            "stopScan" -> stopScan(result)
            "setScanParameters" -> setScanParameters(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun initializeBluetooth() {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
        bluetoothLeScanner = bluetoothAdapter?.bluetoothLeScanner
    }

    private fun initialize(result: Result) {
        try {
            if (bluetoothAdapter == null) {
                result.error("BLUETOOTH_NOT_SUPPORTED", "Bluetooth is not supported on this device", null)
                return
            }
            result.success(null)
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", e.message, null)
        }
    }

    private fun isBluetoothEnabled(result: Result) {
        result.success(bluetoothAdapter?.isEnabled ?: false)
    }

    private fun requestBluetoothEnable(result: Result) {
        // Note: In modern Android, you cannot programmatically enable Bluetooth
        // This would typically show an intent to ask the user to enable Bluetooth
        result.success(bluetoothAdapter?.isEnabled ?: false)
    }

    private fun startScan(result: Result) {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        if (!hasRequiredPermissions()) {
            result.error("PERMISSIONS_DENIED", "Required permissions not granted", null)
            return
        }

        if (isScanning) {
            result.success("ALREADY_SCANNING")
            return
        }

        try {
            val settings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .setCallbackType(ScanSettings.CALLBACK_TYPE_ALL_MATCHES)
                .setReportDelay(0)
                .build()

            bluetoothLeScanner?.startScan(null, settings, scanCallback)
            isScanning = true
            result.success("SCAN_STARTED")
        } catch (e: SecurityException) {
            result.error("PERMISSIONS_DENIED", "Security exception: ${e.message}", null)
        } catch (e: Exception) {
            result.error("SCAN_ERROR", "Failed to start scan: ${e.message}", null)
        }
    }

    private fun stopScan(result: Result) {
        if (!isScanning) {
            result.success("NOT_SCANNING")
            return
        }

        try {
            bluetoothLeScanner?.stopScan(scanCallback)
            isScanning = false
            result.success("SCAN_STOPPED")
        } catch (e: SecurityException) {
            result.error("PERMISSIONS_DENIED", "Security exception: ${e.message}", null)
        } catch (e: Exception) {
            result.error("SCAN_ERROR", "Failed to stop scan: ${e.message}", null)
        }
    }

    private fun setScanParameters(call: MethodCall, result: Result) {
        // This method can be used to configure scan parameters
        // For now, just return success
        result.success(null)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            handleScanResult(result)
        }

        override fun onBatchScanResults(results: MutableList<ScanResult>?) {
            results?.forEach { result ->
                handleScanResult(result)
            }
        }

        override fun onScanFailed(errorCode: Int) {
            val errorMessage = when (errorCode) {
                SCAN_FAILED_ALREADY_STARTED -> "Scan already started"
                SCAN_FAILED_APPLICATION_REGISTRATION_FAILED -> "Application registration failed"
                SCAN_FAILED_FEATURE_UNSUPPORTED -> "Feature unsupported"
                SCAN_FAILED_INTERNAL_ERROR -> "Internal error"
                else -> "Unknown error: $errorCode"
            }
            eventSink?.error("SCAN_FAILED", errorMessage, errorCode)
        }
    }

    private fun handleScanResult(scanResult: ScanResult) {
        try {
            val device = scanResult.device
            val rssi = scanResult.rssi
            val scanRecord = scanResult.scanRecord
            
            val deviceData = mutableMapOf<String, Any>()
            deviceData["deviceId"] = device.address
            deviceData["rssi"] = rssi
            deviceData["lastSeen"] = System.currentTimeMillis()
            
            // Get device name
            val deviceName = try {
                device.name ?: scanRecord?.deviceName ?: ""
            } catch (e: SecurityException) {
                ""
            }
            deviceData["name"] = deviceName
            
            // Parse manufacturer data for iBeacon
            scanRecord?.let { record ->
                val manufacturerData = record.getManufacturerSpecificData(0x004C) // Apple Company ID
                if (manufacturerData != null && manufacturerData.size >= 23) {
                    val beacon = parseIBeacon(manufacturerData, deviceName)
                    if (beacon != null) {
                        deviceData.putAll(beacon)
                    }
                }
            }
            
            // Set default values if not parsed as beacon
            if (!deviceData.containsKey("uuid")) {
                deviceData["uuid"] = ""
                deviceData["major"] = 0
                deviceData["minor"] = 0
                deviceData["protocol"] = "bleDevice"
                deviceData["verified"] = isHolyDevice(deviceName)
            }
            
            eventSink?.success(deviceData)
            
        } catch (e: Exception) {
            // Log error but don't crash
            android.util.Log.e(TAG, "Error processing scan result", e)
        }
    }

    private fun parseIBeacon(data: ByteArray, deviceName: String): Map<String, Any>? {
        if (data.size < 23) return null
        
        try {
            // Check iBeacon format: 0x02, 0x15
            if (data[0] != 0x02.toByte() || data[1] != 0x15.toByte()) return null
            
            // Extract UUID (16 bytes)
            val uuidBytes = data.sliceArray(2..17)
            val uuid = formatUuid(uuidBytes)
            
            // Extract Major (2 bytes)
            val major = ((data[18].toInt() and 0xFF) shl 8) or (data[19].toInt() and 0xFF)
            
            // Extract Minor (2 bytes)
            val minor = ((data[20].toInt() and 0xFF) shl 8) or (data[21].toInt() and 0xFF)
            
            // Extract TX Power (1 byte, signed)
            val txPower = data[22].toInt()
            
            return mapOf(
                "uuid" to uuid,
                "major" to major,
                "minor" to minor,
                "protocol" to "ibeacon",
                "verified" to true
            )
        } catch (e: Exception) {
            android.util.Log.e(TAG, "Error parsing iBeacon", e)
            return null
        }
    }

    private fun formatUuid(bytes: ByteArray): String {
        val hex = bytes.joinToString("") { "%02X".format(it) }
        return "${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}"
    }

    private fun isHolyDevice(deviceName: String): Boolean {
        val name = deviceName.lowercase()
        return name.contains("holy") || name.contains("kronos") || name.contains("blaze")
    }

    private fun hasRequiredPermissions(): Boolean {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            // Android 12+
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        } else {
            // Android 11 and below
            ActivityCompat.checkSelfPermission(context, android.Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        
        if (isScanning) {
            try {
                bluetoothLeScanner?.stopScan(scanCallback)
            } catch (e: SecurityException) {
                // Ignore
            }
        }
    }
}