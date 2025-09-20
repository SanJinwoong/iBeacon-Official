import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  runApp(BeaconScannerApp());
}

class BeaconScannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beacon Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: BeaconScannerPage(),
    );
  }
}

// Simple Beacon Device Class
class SimpleBeaconDevice {
  final String deviceId;
  final String name;
  final int rssi;
  final String? uuid;
  final DateTime lastSeen;
  final bool isHolyDevice;

  SimpleBeaconDevice({
    required this.deviceId,
    required this.name,
    required this.rssi,
    this.uuid,
    required this.lastSeen,
    required this.isHolyDevice,
  });
}

class BeaconScannerPage extends StatefulWidget {
  @override
  _BeaconScannerPageState createState() => _BeaconScannerPageState();
}

class _BeaconScannerPageState extends State<BeaconScannerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, SimpleBeaconDevice> _devices = {};
  List<SimpleBeaconDevice> _filteredDevices = [];
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  bool _isScanning = false;

  // Known Holy UUIDs from successful logs
  static const Set<String> HOLY_UUIDS = {
    'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy-Shun
    'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy-Jin
    'F7826DA6-4FA2-4E98-8024-BC5B71E0893E', // Kronos Blaze
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDevices);
  }

  void _filterDevices() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDevices = _devices.values.toList();
      } else {
        _filteredDevices = _devices.values.where((device) {
          return device.name.toLowerCase().contains(query) ||
              device.deviceId.toLowerCase().contains(query) ||
              (device.uuid?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _startScanning() async {
    try {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      bool hasPermissions = statuses.values.every(
        (status) => status == PermissionStatus.granted,
      );

      if (!hasPermissions) {
        _showError('Permisos de Bluetooth y ubicación requeridos');
        return;
      }

      setState(() {
        _isScanning = true;
        _devices.clear();
      });

      _scanSubscription = _ble
          .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
          .listen(
            _onDeviceDiscovered,
            onError: (error) {
              print('Scan error: $error');
              _showError('Error de escaneo: $error');
            },
          );

      // Auto-stop after 30 seconds
      Timer(Duration(seconds: 30), () {
        if (_isScanning) _stopScanning();
      });
    } catch (e) {
      _showError('Error starting scan: $e');
      setState(() => _isScanning = false);
    }
  }

  void _onDeviceDiscovered(DiscoveredDevice device) {
    // Skip devices without names (unless they're Holy devices)
    if (device.name.isEmpty && !_isHolyDevice(device)) return;

    final simpleDevice = SimpleBeaconDevice(
      deviceId: device.id,
      name: device.name.isNotEmpty ? device.name : 'Unknown Device',
      rssi: device.rssi,
      uuid: _extractUuid(device),
      lastSeen: DateTime.now(),
      isHolyDevice: _isHolyDevice(device),
    );

    setState(() {
      _devices[device.id] = simpleDevice;
      _filterDevices();
    });

    // Log Holy devices
    if (simpleDevice.isHolyDevice) {
      print(
        '🔵 Holy device detected: ${simpleDevice.name} - ${simpleDevice.deviceId}',
      );
    }
  }

  bool _isHolyDevice(DiscoveredDevice device) {
    // Check by name
    if (device.name.toLowerCase().contains('holy') ||
        device.name.toLowerCase().contains('kronos') ||
        device.name.toLowerCase().contains('blaze')) {
      return true;
    }

    // Check by UUID in manufacturer data or service data
    String? uuid = _extractUuid(device);
    if (uuid != null && HOLY_UUIDS.contains(uuid.toUpperCase())) {
      return true;
    }

    return false;
  }

  String? _extractUuid(DiscoveredDevice device) {
    // Try to extract from service UUIDs first
    if (device.serviceUuids.isNotEmpty) {
      return device.serviceUuids.first.toString().toUpperCase();
    }

    // Try manufacturer data
    if (device.manufacturerData.isNotEmpty) {
      // This is a simplified UUID extraction
      return device.id.replaceAll(':', '').toUpperCase();
    }

    return null;
  }

  Future<void> _stopScanning() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    setState(() => _isScanning = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Beacon Scanner'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Scan Controls
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search TextField
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar dispositivos...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                SizedBox(height: 16),

                // Scan Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isScanning ? _stopScanning : _startScanning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isScanning ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isScanning ? Icons.stop : Icons.search),
                        SizedBox(width: 8),
                        Text(
                          _isScanning ? 'Detener' : 'Escanear',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Information
          if (_isScanning)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Text(
                'Escaneando... ${_devices.length} dispositivos encontrados',
                style: TextStyle(color: Colors.blue[700], fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),

          // Device List
          Expanded(
            child: _filteredDevices.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredDevices.length,
                    itemBuilder: (context, index) {
                      final device = _filteredDevices[index];
                      return _buildDeviceCard(device);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bluetooth_searching, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            _isScanning
                ? 'Buscando dispositivos...'
                : 'Presiona "Escanear" para buscar beacons',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(SimpleBeaconDevice device) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: device.isHolyDevice
                ? [Colors.blue[400]!, Colors.blue[600]!]
                : [Colors.grey[100]!, Colors.grey[200]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: device.isHolyDevice
                          ? Colors.white.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'BLE',
                      style: TextStyle(
                        color: device.isHolyDevice
                            ? Colors.white
                            : Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Spacer(),
                  if (device.isHolyDevice)
                    Icon(Icons.verified, color: Colors.white, size: 20),
                ],
              ),
              SizedBox(height: 12),

              // Device Name
              Text(
                device.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: device.isHolyDevice ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 8),

              // Device ID
              Text(
                device.deviceId,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: device.isHolyDevice
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),

              // UUID if available
              if (device.uuid != null && device.uuid!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'UUID: ${device.uuid}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: device.isHolyDevice
                        ? Colors.white70
                        : Colors.grey[600],
                  ),
                ),
              ],

              SizedBox(height: 12),

              // RSSI
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRssiColor(device.rssi).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${device.rssi} dBm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: device.isHolyDevice
                            ? Colors.white
                            : _getRssiColor(device.rssi),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -50) return Colors.green;
    if (rssi > -70) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanSubscription?.cancel();
    super.dispose();
  }
}
