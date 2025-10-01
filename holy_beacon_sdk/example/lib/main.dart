import 'package:flutter/material.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

void main() {
  runApp(const HolyBeaconExampleApp());
}

class HolyBeaconExampleApp extends StatelessWidget {
  const HolyBeaconExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Holy Beacon SDK Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HolyBeaconExamplePage(),
    );
  }
}

class HolyBeaconExamplePage extends StatefulWidget {
  const HolyBeaconExamplePage({super.key});

  @override
  State<HolyBeaconExamplePage> createState() => _HolyBeaconExamplePageState();
}

class _HolyBeaconExamplePageState extends State<HolyBeaconExamplePage>
    with TickerProviderStateMixin {
  final HolyBeaconScanner _scanner = HolyBeaconScanner();
  final TextEditingController _uuidController = TextEditingController();
  final TextEditingController _uuidListController = TextEditingController();

  List<BeaconDevice> _devices = [];
  String _status = 'Ready to scan';
  bool _isScanning = false;

  // UUID Processor Results
  UuidProcessingResult? _singleUuidResult;
  UuidListProcessingResult? _uuidListResult;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeScanner();

    // Pre-fill examples
    _uuidController.text = 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825';
    _uuidListController.text = '''FDA50693-A4E2-4FB1-AFCF-C6EB07647825
E2C56DB5-DFFB-48D2-B060-D0F5A7100000
F7826DA6-4FA2-4E98-8024-BC5B71E0893E
12345678-1234-5678-9012-123456789012
invalid-uuid-example''';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uuidController.dispose();
    _uuidListController.dispose();
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _initializeScanner() async {
    try {
      await _scanner.initialize(
        config: BeaconScanConfig.holyOptimized(),
        whitelist: BeaconWhitelist.allowAll(),
      );

      _scanner.devices.listen((devices) {
        setState(() {
          _devices = devices;
        });
      });

      _scanner.status.listen((status) {
        setState(() {
          _status = status;
        });
      });
    } catch (e) {
      setState(() {
        _status = 'Initialization error: $e';
      });
    }
  }

  Future<void> _startScanning() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      await _scanner.startScanning();
    } catch (e) {
      setState(() {
        _status = 'Scan error: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _stopScanning() async {
    if (!_isScanning) return;

    await _scanner.stopScanning();
    setState(() {
      _isScanning = false;
    });
  }

  void _processSingleUuid() {
    final uuid = _uuidController.text.trim();
    if (uuid.isEmpty) return;

    setState(() {
      _singleUuidResult = UuidProcessor.processSingleUuid(
        uuid,
        validateFormat: true,
        normalizeFormat: true,
      );
    });
  }

  void _processUuidList() {
    final uuidsText = _uuidListController.text.trim();
    if (uuidsText.isEmpty) return;

    final uuids = uuidsText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    setState(() {
      _uuidListResult = UuidProcessor.processUuidList(
        uuids,
        filterInvalid: false,
        prioritizeHoly: true,
        validateFormat: true,
        normalizeFormat: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holy Beacon SDK Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth_searching), text: 'Scanner'),
            Tab(icon: Icon(Icons.code), text: 'Single UUID'),
            Tab(icon: Icon(Icons.list), text: 'UUID List'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScannerTab(),
          _buildSingleUuidTab(),
          _buildUuidListTab(),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Column(
      children: [
        // Status Card
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                      color: _isScanning ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scanner Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_status),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _startScanning,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Scanning'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? _stopScanning : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Scanning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Devices List
        Expanded(
          child: _devices.isEmpty
              ? const Center(
                  child: Text(
                    'No devices found yet.\nStart scanning to discover beacons.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return _buildDeviceCard(device);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BeaconDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: device.isHolyDevice ? Colors.deepPurple.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  device.isHolyDevice ? Icons.verified : Icons.bluetooth,
                  color: device.isHolyDevice ? Colors.deepPurple : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    device.name,
                    style: TextStyle(
                      fontWeight: device.isHolyDevice
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        device.isHolyDevice ? Colors.deepPurple : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${device.rssi} dBm',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            if (device.uuid.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'UUID: ${device.uuid}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
            if (device.protocol == BeaconProtocol.ibeacon) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Major: ${device.major}'),
                  const SizedBox(width: 16),
                  Text('Minor: ${device.minor}'),
                  const SizedBox(width: 16),
                  Text('Protocol: ${device.protocol.name}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSingleUuidTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Single UUID Processing',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _uuidController,
            decoration: const InputDecoration(
              labelText: 'Enter UUID',
              hintText: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _processSingleUuid,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Process UUID'),
          ),
          const SizedBox(height: 24),
          if (_singleUuidResult != null) ...[
            Text(
              'Processing Result:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSingleUuidResultCard(_singleUuidResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleUuidResultCard(UuidProcessingResult result) {
    return Card(
      color: result.isValid
          ? (result.isHolyDevice
              ? Colors.green.withOpacity(0.1)
              : Colors.blue.withOpacity(0.1))
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isValid
                      ? (result.isHolyDevice
                          ? Icons.verified
                          : Icons.check_circle)
                      : Icons.error,
                  color: result.isValid
                      ? (result.isHolyDevice ? Colors.green : Colors.blue)
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  result.isValid ? 'Valid UUID' : 'Invalid UUID',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildResultRow('Original', result.originalUuid),
            if (result.isValid) ...[
              _buildResultRow('Normalized', result.normalizedUuid),
              _buildResultRow(
                  'Holy Device', result.isHolyDevice ? 'Yes' : 'No'),
              if (result.isHolyDevice) ...[
                _buildResultRow('Category', result.deviceCategory.name),
                _buildResultRow('Device Type', result.deviceType),
                _buildResultRow('Trust Level', '${result.trustLevel}/10'),
              ],
            ] else ...[
              _buildResultRow(
                  'Error Type', result.errorType?.name ?? 'Unknown'),
              _buildResultRow(
                  'Error Message', result.errorMessage ?? 'No message'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUuidListTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UUID List Processing',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _uuidListController,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Enter UUIDs (one per line)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _processUuidList,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Process UUID List'),
          ),
          const SizedBox(height: 24),
          if (_uuidListResult != null) ...[
            Text(
              'Processing Results:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildUuidListResultCard(_uuidListResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildUuidListResultCard(UuidListProcessingResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildResultRow('Total Processed', '${result.totalProcessed}'),
            _buildResultRow('Valid UUIDs', '${result.validCount}'),
            _buildResultRow('Invalid UUIDs', '${result.invalidCount}'),
            _buildResultRow('Holy Devices', '${result.holyDeviceCount}'),
            _buildResultRow(
                'Success Rate', '${result.successRate.toStringAsFixed(1)}%'),
            _buildResultRow('Holy Device Rate',
                '${result.holyDeviceRate.toStringAsFixed(1)}%'),
            if (result.holyResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Holy Devices Found:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...result.holyResults
                  .map((holyResult) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              holyResult.normalizedUuid,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${holyResult.deviceType} (Trust: ${holyResult.trustLevel})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
            if (result.invalidResults.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Invalid UUIDs:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...result.invalidResults
                  .map((invalidResult) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invalidResult.originalUuid,
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                            Text(
                              invalidResult.errorMessage ?? 'Unknown error',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.red),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
