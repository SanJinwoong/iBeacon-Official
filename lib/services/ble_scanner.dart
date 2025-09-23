import 'dart:async';
import '../models/beacon_models.dart';
import 'ble_service.dart';

/// Interface for beacon scanning functionality
/// This provides a common contract for different beacon scanner implementations
abstract class IBeaconScanner {
  /// Stream of detected beacon devices
  Stream<List<BeaconDevice>> get devicesStream;

  /// Stream of status messages
  Stream<String> get statusStream => const Stream.empty();

  /// Whether the scanner is currently scanning
  bool get isScanning;

  /// Set a whitelist of allowed devices
  void setWhitelist(BeaconWhitelist whitelist);

  /// Start scanning for beacons
  /// [filterUuid] - Optional UUID filter to only scan for specific beacons
  void start({String? filterUuid});

  /// Stop scanning
  void stop();

  /// Clean up resources
  void dispose();
}

/// Default implementation using BleService
class DefaultBeaconScanner implements IBeaconScanner {
  final BleService _bleService;
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _statusSubscription;

  final _devicesController = StreamController<List<BeaconDevice>>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  BeaconWhitelist? _whitelist;

  DefaultBeaconScanner(this._bleService);

  @override
  Stream<List<BeaconDevice>> get devicesStream => _devicesController.stream;

  @override
  Stream<String> get statusStream => _statusController.stream;

  @override
  bool get isScanning => _bleService.isScanning;

  @override
  void setWhitelist(BeaconWhitelist whitelist) {
    _whitelist = whitelist;
  }

  @override
  void start({String? filterUuid}) {
    // Listen to BLE service streams
    _devicesSubscription?.cancel();
    _statusSubscription?.cancel();

    _devicesSubscription = _bleService.devices.listen((devices) {
      List<BeaconDevice> filteredDevices = devices;

      // Apply whitelist if set
      if (_whitelist != null) {
        filteredDevices = devices.where(_whitelist!.isAllowed).toList();
      }

      // Apply UUID filter if provided
      if (filterUuid != null) {
        filteredDevices = filteredDevices
            .where((device) =>
                device.uuid.toUpperCase().contains(filterUuid.toUpperCase()))
            .toList();
      }

      _devicesController.add(filteredDevices);
    });

    _statusSubscription = _bleService.status.listen((status) {
      _statusController.add(status);
    });

    // Start the actual scanning
    _bleService.startScanning();
  }

  @override
  void stop() {
    _bleService.stopScanning();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _statusSubscription?.cancel();
    _devicesController.close();
    _statusController.close();
    _bleService.dispose();
  }
}
