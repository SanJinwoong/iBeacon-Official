import 'package:flutter/material.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holy Beacon SDK Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BeaconScannerExample(),
    );
  }
}

class BeaconScannerExample extends StatefulWidget {
  @override
  _BeaconScannerExampleState createState() => _BeaconScannerExampleState();
}

class _BeaconScannerExampleState extends State<BeaconScannerExample> {
  final HolyBeaconScanner scanner = HolyBeaconScanner();
  List<BeaconDevice> devices = [];
  String status = 'Ready to scan';
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    // Initialize with Holy devices priority
    await scanner.initialize(
      config: BeaconScanConfig.holyOptimized(),
      whitelist: BeaconWhitelist.allowAll(),
    );

    // Listen to device updates
    scanner.devices.listen((deviceList) {
      setState(() {
        devices = deviceList;
      });
    });

    // Listen to status updates
    scanner.status.listen((statusMessage) {
      setState(() {
        status = statusMessage;
      });
    });

    // Listen to errors
    scanner.errors.listen((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.message}'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<void> _toggleScanning() async {
    if (scanner.isScanning) {
      await scanner.stopScanning();
      setState(() {
        isScanning = false;
      });
    } else {
      await scanner.startScanning();
      setState(() {
        isScanning = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Holy Beacon SDK Example'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanner Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(status),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleScanning,
                          icon:
                              Icon(isScanning ? Icons.stop : Icons.play_arrow),
                          label: Text(
                              isScanning ? 'Stop Scanning' : 'Start Scanning'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isScanning ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          scanner.clearDevices();
                        },
                        child: Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Devices Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discovered Devices (${devices.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (devices.isNotEmpty)
                  Text(
                    'Holy: ${devices.where((d) => d.isHolyDevice).length}',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Devices List
          Expanded(
            child: devices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          isScanning
                              ? 'Searching for devices...'
                              : 'Press "Start Scanning" to begin',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      return _buildDeviceCard(devices[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BeaconDevice device) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: device.isHolyDevice
              ? LinearGradient(
                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Name with Holy Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      device.name.isNotEmpty ? device.name : 'Unknown Device',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            device.isHolyDevice ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (device.isHolyDevice) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'HOLY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (device.verified && !device.isHolyDevice)
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),

              SizedBox(height: 12),

              // Device Info Grid
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'RSSI',
                      '${device.rssi} dBm',
                      Icons.signal_cellular_alt,
                      device.isHolyDevice ? Colors.white70 : Colors.grey[600]!,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Distance',
                      device.getLocalizedDistance('es'),
                      Icons.location_on,
                      device.isHolyDevice ? Colors.white70 : Colors.grey[600]!,
                    ),
                  ),
                ],
              ),

              if (device.uuid.isNotEmpty) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'UUID',
                        device.uuid,
                        Icons.fingerprint,
                        device.isHolyDevice
                            ? Colors.white70
                            : Colors.grey[600]!,
                        isUuid: true,
                      ),
                    ),
                  ],
                ),
              ],

              if (device.protocol == BeaconProtocol.ibeacon) ...[
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Major',
                        '${device.major}',
                        Icons.numbers,
                        device.isHolyDevice
                            ? Colors.white70
                            : Colors.grey[600]!,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        'Minor',
                        '${device.minor}',
                        Icons.numbers,
                        device.isHolyDevice
                            ? Colors.white70
                            : Colors.grey[600]!,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 8),

              // Protocol Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.isHolyDevice
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  device.protocol.name.toUpperCase(),
                  style: TextStyle(
                    color:
                        device.isHolyDevice ? Colors.white : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color,
      {bool isUuid = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          isUuid ? value.substring(0, 8) + '...' : value,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
