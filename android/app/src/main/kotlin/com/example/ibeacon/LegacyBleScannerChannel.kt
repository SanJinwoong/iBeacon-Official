package com.example.ibeacon

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LegacyBleScannerChannel(context: Context, channel: MethodChannel) : MethodCallHandler {
    private val context = context
    private val resultChannel = channel
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var isScanning = false
    private val handler = Handler(Looper.getMainLooper())
    private val scannedDevices = mutableSetOf<String>()

    companion object {
        private const val TAG = "LegacyBleScannerChannel"
    }

    init {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        bluetoothAdapter = bluetoothManager.adapter
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startLegacyScan" -> startScan(result)
            "stopLegacyScan" -> stopScan(result)
            else -> result.notImplemented()
        }
    }

    @Suppress("DEPRECATION")
    private fun startScan(result: Result) {
        if (bluetoothAdapter == null || !bluetoothAdapter!!.isEnabled) {
            result.error("BLUETOOTH_DISABLED", "Bluetooth is not enabled", null)
            return
        }

        if (!hasPermissions()) {
            result.error("PERMISSIONS_DENIED", "Required permissions not granted", null)
            return
        }

        if (isScanning) {
            result.success("ALREADY_SCANNING")
            return
        }

        try {
            scannedDevices.clear()
            isScanning = true
            
            Log.w(TAG, "🚀 STARTING LEGACY BLE SCAN (Old API)")
            Log.w(TAG, "🔍 This uses the deprecated API which sometimes finds more devices")
            
            // Use deprecated API for better compatibility
            bluetoothAdapter!!.startLeScan(leScanCallback)
            
            result.success("LEGACY_SCAN_STARTED")
            
            // Auto-stop after 30 seconds
            handler.postDelayed({
                if (isScanning) {
                    stopScan(null)
                }
            }, 30000)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error starting legacy scan: ${e.message}")
            result.error("SCAN_ERROR", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    private fun stopScan(result: Result?) {
        if (!isScanning) {
            result?.success("NOT_SCANNING")
            return
        }

        try {
            bluetoothAdapter?.stopLeScan(leScanCallback)
            isScanning = false
            Log.d(TAG, "🛑 Legacy scan stopped")
            result?.success("LEGACY_SCAN_STOPPED")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error stopping legacy scan: ${e.message}")
            result?.error("STOP_ERROR", e.message, null)
        }
    }

    @Suppress("DEPRECATION")
    private val leScanCallback = BluetoothAdapter.LeScanCallback { device, rssi, scanRecord ->
        try {
            val deviceAddress = device.address
            val deviceName = device.name ?: "Unknown"
            
            // Skip duplicates
            val deviceKey = "$deviceAddress-$deviceName"
            if (scannedDevices.contains(deviceKey)) {
                return@LeScanCallback
            }
            scannedDevices.add(deviceKey)
            
            Log.w(TAG, "📡 LEGACY SCAN DEVICE FOUND!")
            Log.w(TAG, "📱 Device: $deviceName ($deviceAddress)")
            Log.w(TAG, "📶 RSSI: $rssi")
            Log.w(TAG, "📡 Raw data length: ${scanRecord?.size ?: 0}")
            
            // Critical Holy-Jin checks
            if (deviceAddress == "C3:FB:F2:58:F1:BD") {
                Log.e(TAG, "🚨🚨🚨 HOLY-JIN MAC FOUND BY LEGACY SCAN! 🚨🚨🚨")
            }
            
            if (deviceName.contains("Jin", ignoreCase = true) || 
                deviceName.contains("Holy", ignoreCase = true) ||
                deviceName.contains("HolyIOT", ignoreCase = true)) {
                Log.e(TAG, "🚨🚨🚨 HOLY DEVICE NAME FOUND BY LEGACY SCAN! 🚨🚨🚨")
                Log.e(TAG, "🚨 Name: $deviceName")
            }
            
            // Parse scan record if available
            scanRecord?.let { record ->
                val hexData = record.joinToString("") { "%02X".format(it) }
                Log.w(TAG, "📊 Raw scan record: $hexData")
                
                // Look for Holy-Jin UUID fragments
                if (hexData.contains("E2C56DB5", ignoreCase = true) ||
                    hexData.contains("DFFB48D2", ignoreCase = true) ||
                    hexData.contains("B060D0F5", ignoreCase = true)) {
                    Log.e(TAG, "🚨🚨🚨 HOLY-JIN UUID FRAGMENTS FOUND IN LEGACY SCAN! 🚨🚨🚨")
                }
                
                // Look for iBeacon format
                if (hexData.contains("0215", ignoreCase = true)) {
                    Log.e(TAG, "🎯 iBeacon FORMAT DETECTED BY LEGACY SCAN!")
                }
                
                // Parse manufacturer data
                parseScanRecord(record, deviceName, deviceAddress)
            }
            
            // Send to Flutter
            val deviceData = mapOf(
                "name" to deviceName,
                "address" to deviceAddress,
                "rssi" to rssi,
                "scanRecord" to (scanRecord?.joinToString("") { "%02X".format(it) } ?: ""),
                "isLegacyScan" to true,
                "timestamp" to System.currentTimeMillis()
            )
            
            handler.post {
                resultChannel.invokeMethod("onLegacyDeviceFound", deviceData)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error processing legacy scan result: ${e.message}")
        }
    }

    private fun parseScanRecord(scanRecord: ByteArray, deviceName: String, deviceAddress: String) {
        try {
            var index = 0
            while (index < scanRecord.size) {
                if (index + 1 >= scanRecord.size) break
                
                val length = scanRecord[index].toInt() and 0xFF
                if (length == 0 || index + length >= scanRecord.size) break
                
                val type = scanRecord[index + 1].toInt() and 0xFF
                val data = scanRecord.copyOfRange(index + 2, index + 1 + length)
                
                when (type) {
                    0xFF -> {
                        // Manufacturer data
                        if (data.size >= 2) {
                            val companyId = ((data[1].toInt() and 0xFF) shl 8) or (data[0].toInt() and 0xFF)
                            val manufacturerData = data.copyOfRange(2, data.size)
                            val hexData = manufacturerData.joinToString("") { "%02X".format(it) }
                            
                            Log.w(TAG, "🏭 LEGACY: Company ID: 0x%04X - Data: %s".format(companyId, hexData))
                            
                            // Check for Holy-Jin specific data
                            if (hexData.contains("E2C56DB5", ignoreCase = true) ||
                                hexData.contains("DFFB48D2", ignoreCase = true)) {
                                Log.e(TAG, "🚨🚨🚨 HOLY-JIN DATA FOUND IN MANUFACTURER DATA! 🚨🚨🚨")
                            }
                        }
                    }
                    0x09 -> {
                        // Complete local name
                        val name = String(data, Charsets.UTF_8)
                        Log.w(TAG, "📱 LEGACY: Complete name: $name")
                        if (name.contains("Jin", ignoreCase = true) || name.contains("Holy", ignoreCase = true)) {
                            Log.e(TAG, "🚨🚨🚨 HOLY NAME IN SCAN RECORD! 🚨🚨🚨")
                        }
                    }
                }
                
                index += 1 + length
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error parsing scan record: ${e.message}")
        }
    }

    private fun hasPermissions(): Boolean {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                android.Manifest.permission.BLUETOOTH_SCAN,
                android.Manifest.permission.BLUETOOTH_CONNECT,
                android.Manifest.permission.ACCESS_FINE_LOCATION
            )
        } else {
            arrayOf(
                android.Manifest.permission.BLUETOOTH,
                android.Manifest.permission.BLUETOOTH_ADMIN,
                android.Manifest.permission.ACCESS_FINE_LOCATION
            )
        }

        return permissions.all { permission ->
            ActivityCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
        }
    }
}
