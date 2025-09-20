import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/beacon_models.dart';
import '../parsers/beacon_parsers.dart';

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  final _devicesController = StreamController<List<BeaconDevice>>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  final _devices = <String, BeaconDevice>{};

  Stream<List<BeaconDevice>> get devices => _devicesController.stream;
  Stream<String> get status => _statusController.stream;
  bool get isScanning => _scanSubscription != null;

  Future<bool> requestPermissions() async {
    try {
      final permissions = [
        Permission.location,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
      ];

      final statuses = await permissions.request();
      final allGranted = statuses.values.every(
        (status) =>
            status == PermissionStatus.granted ||
            status == PermissionStatus.limited,
      );

      if (!allGranted) {
        _statusController.add('⚠️ Permisos BLE no otorgados completamente');
        // Print detailed permission status
        for (final entry in statuses.entries) {
          print('${entry.key}: ${entry.value}');
        }
      }

      return allGranted;
    } catch (e) {
      _statusController.add('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  Future<void> startScanning() async {
    if (isScanning) await stopScanning();

    try {
      final hasPermissions = await requestPermissions();
      if (!hasPermissions) {
        _statusController.add('⚠️ Permisos insuficientes para escanear');
        return;
      }

      _devices.clear();
      _emitDevices();
      _statusController.add('🔍 Iniciando escaneo BLE...');

      // Use aggressive scan settings for maximum detection
      _scanSubscription = _ble
          .scanForDevices(
            withServices: [], // Scan for all devices
            scanMode: ScanMode.lowLatency, // Most aggressive scan
            requireLocationServicesEnabled: false,
          )
          .listen(
            _onDeviceDiscovered,
            onError: (e) {
              print('❌ Error de escaneo: $e');
              _statusController.add('❌ Error de escaneo: $e');
            },
          );

      _statusController.add('✅ Escaneo activo');
    } catch (e) {
      _statusController.add('❌ Fallo al iniciar escaneo: $e');
      print('❌ Fallo al iniciar escaneo: $e');
    }
  }

  Future<void> stopScanning() async {
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _statusController.add('⏹️ Escaneo detenido');
      print('⏹️ Escaneo detenido');
    } catch (e) {
      print('❌ Error deteniendo escaneo: $e');
    }
  }

  void _onDeviceDiscovered(DiscoveredDevice device) {
    final detectedBeacons = <BeaconDevice>[];

    // Try to parse as iBeacon from manufacturer data
    if (device.manufacturerData.isNotEmpty) {
      final manufacturerData = device.manufacturerData;
      final beacon = BeaconParsers.tryParseIBeacon(
        device.id,
        device.name,
        device.rssi,
        manufacturerData,
      );
      if (beacon != null) {
        detectedBeacons.add(beacon);
        print('📱 iBeacon detected: ${beacon.name} (${beacon.uuid})');
      }
    }

    // Try to parse as Eddystone from service data
    if (device.serviceData.isNotEmpty) {
      final serviceData = device.serviceData;
      final eddystoneBeacon = BeaconParsers.tryParseEddystone(
        device.id,
        device.name,
        device.rssi,
        serviceData,
      );
      if (eddystoneBeacon != null) {
        detectedBeacons.add(eddystoneBeacon);
        print('📡 Eddystone detected: ${device.name}');
      }
    }

    // Create generic BLE device if no beacon data but has name or manufacturer data
    if (detectedBeacons.isEmpty) {
      final genericDevice = BeaconParsers.tryParseGenericBLE(
        device.id,
        device.name,
        device.rssi,
        device.manufacturerData.isNotEmpty ? device.manufacturerData : null,
      );
      detectedBeacons.add(genericDevice);
      print('📶 BLE device: ${genericDevice.name}');
    }

    // Update device list
    for (final beacon in detectedBeacons) {
      final key = '${beacon.deviceId}_${beacon.protocol.name}';
      _devices[key] = beacon;

      // Special logging for Holy devices
      if (beacon.isHolyDevice) {
        print('🎯 HOLY DEVICE FOUND: ${beacon.name} - ${beacon.deviceId}');
        print('   UUID: ${beacon.uuid}');
        print('   Major: ${beacon.major}, Minor: ${beacon.minor}');
        print('   RSSI: ${beacon.rssi} dBm');
        print('   Verified: ${beacon.verified}');
      }
    }

    _emitDevices();
  }

  void _emitDevices() {
    final sortedDevices = _devices.values.toList()
      ..sort((a, b) {
        // Holy devices first
        if (a.isHolyDevice && !b.isHolyDevice) return -1;
        if (!a.isHolyDevice && b.isHolyDevice) return 1;

        // Verified beacons next
        if (a.verified && !b.verified) return -1;
        if (!a.verified && b.verified) return 1;

        // iBeacons before other types
        if (a.protocol == BeaconProtocol.ibeacon &&
            b.protocol != BeaconProtocol.ibeacon)
          return -1;
        if (a.protocol != BeaconProtocol.ibeacon &&
            b.protocol == BeaconProtocol.ibeacon)
          return 1;

        // Then by RSSI (stronger signal first)
        return b.rssi.compareTo(a.rssi);
      });

    _devicesController.add(sortedDevices);

    // Update status with device count
    final totalDevices = sortedDevices.length;
    final holyDevices = sortedDevices.where((d) => d.isHolyDevice).length;
    final verifiedDevices = sortedDevices.where((d) => d.verified).length;

    if (isScanning) {
      _statusController.add(
        '🔍 Escaneando: $totalDevices dispositivos '
        '(Holy: $holyDevices, Verificados: $verifiedDevices)',
      );
    }
  }

  void clearDevices() {
    _devices.clear();
    _emitDevices();
  }

  void dispose() {
    stopScanning();
    _devicesController.close();
    _statusController.close();
  }
}
