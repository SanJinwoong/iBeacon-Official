import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iBeacon Scanner',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const BeaconScannerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SimpleBeaconDevice {
  final String deviceId;
  final String name;
  final int rssi;
  final DateTime lastSeen;
  final String? uuid;
  final int? major;
  final int? minor;
  final int? txPower;

  SimpleBeaconDevice({
    required this.deviceId,
    required this.name,
    required this.rssi,
    required this.lastSeen,
    this.uuid,
    this.major,
    this.minor,
    this.txPower,
  });

  SimpleBeaconDevice copyWith({
    int? rssi,
    DateTime? lastSeen,
  }) {
    return SimpleBeaconDevice(
      deviceId: deviceId,
      name: name,
      rssi: rssi ?? this.rssi,
      lastSeen: lastSeen ?? this.lastSeen,
      uuid: uuid,
      major: major,
      minor: minor,
      txPower: txPower,
    );
  }
}

class BeaconScannerPage extends StatefulWidget {
  const BeaconScannerPage({super.key});

  @override
  _BeaconScannerPageState createState() => _BeaconScannerPageState();
}

class _BeaconScannerPageState extends State<BeaconScannerPage> {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final Map<String, SimpleBeaconDevice> _devices = {};
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  bool _isScanning = false;
  String _searchFilter = '';

  // Control de frecuencia de actualización
  DateTime _lastUpdate = DateTime.now();
  static const Duration _updateInterval =
      Duration(milliseconds: 500); // Actualizar cada 500ms máximo

  @override
  void initState() {
    super.initState();
    // Inicializar permisos de manera no-bloqueante
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePermissions();
    });
  }

  Future<void> _initializePermissions() async {
    try {
      await _checkAndRequestPermissions();
      // Verificar permisos críticos al iniciar (con delay para no bloquear UI)
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _checkCriticalPermissions();
      }
    } catch (e) {
      print('Error en inicialización de permisos: $e');
    }
  }

  Future<void> _checkCriticalPermissions() async {
    try {
      List<String> missingPermissions = [];

      // Verificar permisos de ubicación (necesarios en todas las plataformas)
      final locationWhenInUseStatus = await Permission.locationWhenInUse.status;
      if (!locationWhenInUseStatus.isGranted) {
        missingPermissions.add('Ubicación cuando la app está en uso');
      }

      // En iOS, verificar si necesitamos ubicación siempre para background
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        final locationAlwaysStatus = await Permission.locationAlways.status;
        if (!locationAlwaysStatus.isGranted) {
          missingPermissions.add('Ubicación en segundo plano (recomendado)');
        }

        // Para iOS, verificar permisos de Bluetooth
        final bluetoothStatus = await Permission.bluetooth.status;
        if (!bluetoothStatus.isGranted) {
          missingPermissions.add('Bluetooth');
        }
      } else {
        // Para Android, usar los permisos específicos
        try {
          final bluetoothScanStatus = await Permission.bluetoothScan.status;
          if (!bluetoothScanStatus.isGranted) {
            missingPermissions.add('Escaneo Bluetooth');
          }

          final bluetoothConnectStatus =
              await Permission.bluetoothConnect.status;
          if (!bluetoothConnectStatus.isGranted) {
            missingPermissions.add('Conexión Bluetooth');
          }
        } catch (e) {
          // Fallback para versiones anteriores de Android
          final bluetoothStatus = await Permission.bluetooth.status;
          if (!bluetoothStatus.isGranted) {
            missingPermissions.add('Bluetooth');
          }
        }
      }

      if (missingPermissions.isNotEmpty && mounted) {
        await _showCriticalPermissionsDialog(missingPermissions);
      }
    } catch (e) {
      print('Error verificando permisos críticos: $e');
    }
  }

  Future<void> _showCriticalPermissionsDialog(
      List<String> missingPermissions) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Permisos Críticos'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'La aplicación necesita los siguientes permisos para funcionar:'),
              const SizedBox(height: 16),
              ...missingPermissions.map(
                (perm) => Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(perm,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin estos permisos, no podrás escanear beacons. Ve a Configuración para habilitarlos.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Después'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings();
              },
              child: const Text('Ir a Configuración'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = {};

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // Permisos para iOS
        statuses = await [
          Permission.locationWhenInUse,
          Permission.locationAlways,
          Permission.bluetooth,
        ].request();
      } else {
        // Permisos para Android
        List<Permission> androidPermissions = [
          Permission.location,
          Permission.locationWhenInUse,
        ];

        // Intentar añadir permisos específicos de Android 12+
        try {
          androidPermissions.addAll([
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ]);
        } catch (e) {
          // Fallback para versiones anteriores
          androidPermissions.add(Permission.bluetooth);
        }

        statuses = await androidPermissions.request();
      }

      // Log del estado de los permisos para debugging
      for (final entry in statuses.entries) {
        print('Permiso ${entry.key}: ${entry.value}');

        // Si el permiso fue denegado, mostrar información adicional
        if (entry.value.isDenied || entry.value.isPermanentlyDenied) {
          print('⚠️ Permiso ${entry.key} fue denegado');
        }
      }

      // Verificar si necesitamos mostrar diálogo para ir a configuración
      final hasPermamentlyDenied =
          statuses.values.any((status) => status.isPermanentlyDenied);
      if (hasPermamentlyDenied && mounted) {
        _showGoToSettingsDialog();
      }
    } catch (e) {
      print('Error al solicitar permisos: $e');
    }
  }

  Future<void> _showGoToSettingsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.settings, color: Colors.orange),
              SizedBox(width: 8),
              Text('Configurar Permisos'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Algunos permisos fueron denegados permanentemente. Para que la aplicación funcione correctamente, necesitas habilitarlos manualmente en Configuración.',
              ),
              SizedBox(height: 16),
              Text(
                'Ve a: Configuración > Privacidad y Seguridad > Ubicación/Bluetooth',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Después'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings();
              },
              child: const Text('Abrir Configuración'),
            ),
          ],
        );
      },
    );
  }

  void _toggleScanning() {
    if (_isScanning) {
      _stopScanning();
    } else {
      _startScanning();
    }
  }

  void _startScanning() {
    if (_scanSubscription != null) {
      _scanSubscription!.cancel();
    }

    setState(() {
      _isScanning = true;
    });

    _scanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen(
      _onDeviceDiscovered,
      onError: (error) {
        print('Error de escaneo: $error');
        setState(() {
          _isScanning = false;
        });
      },
    );
  }

  void _stopScanning() {
    _scanSubscription?.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  void _onDeviceDiscovered(DiscoveredDevice device) {
    final String deviceId = device.id;
    final String deviceName =
        device.name.isNotEmpty ? device.name : 'Dispositivo Desconocido';

    // Control de frecuencia - solo actualizar cada 500ms
    final now = DateTime.now();
    final shouldUpdate = now.difference(_lastUpdate) > _updateInterval;

    // Intentar parsear datos iBeacon del manufacturerData
    String? uuid;
    int? major;
    int? minor;
    int? txPower;

    final Uint8List manufacturerData = device.manufacturerData;

    if (manufacturerData.isNotEmpty) {
      // Debug: mostrar datos raw del manufacturerData
      print(
          '📊 Datos raw para $deviceName: ${manufacturerData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      if (manufacturerData.length >= 25) {
        // Buscar el formato iBeacon en los datos
        // Los primeros 2 bytes son el Company ID (little-endian)
        // Para Apple: 0x4C 0x00
        if (manufacturerData.length >= 25 &&
            manufacturerData[0] == 0x4C &&
            manufacturerData[1] == 0x00) {
          // Verificar el formato iBeacon: [Company ID][0x02][0x15][UUID][Major][Minor][TX Power]
          if (manufacturerData[2] == 0x02 && manufacturerData[3] == 0x15) {
            // Extraer UUID (16 bytes, desde posición 4 hasta 19)
            final uuidBytes = manufacturerData.sublist(4, 20);
            uuid = _formatUuid(uuidBytes);

            // Extraer Major (2 bytes, posiciones 20-21, big-endian)
            major = (manufacturerData[20] << 8) | manufacturerData[21];

            // Extraer Minor (2 bytes, posiciones 22-23, big-endian)
            minor = (manufacturerData[22] << 8) | manufacturerData[23];

            // Extraer TX Power (1 byte con signo, posición 24)
            txPower = _signedInt8(manufacturerData[24]);
          }
        }
      }

      // Si no se encontró como iBeacon de Apple, intentar otros formatos
      if (uuid == null && manufacturerData.length >= 6) {
        // Para dispositivos Holy que usan formato personalizado
        if (deviceName.toLowerCase().contains('holy')) {
          // Crear un UUID dummy basado en los primeros bytes del manufacturerData
          String hexData = manufacturerData
              .take(16)
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join('');
          if (hexData.length >= 32) {
            uuid =
                '${hexData.substring(0, 8)}-${hexData.substring(8, 12)}-${hexData.substring(12, 16)}-${hexData.substring(16, 20)}-${hexData.substring(20, 32)}';
            // Valores dummy para completar la información
            major = 1;
            minor = 1;
            txPower = -59;
          }
        }
      }
    }

    // Determinar el nombre apropiado para el dispositivo
    String finalDeviceName = deviceName;
    if (uuid != null) {
      const holyUuids = {
        'FDA50693-A4E2-4FB1-AFCF-C6EB07647825': 'Holy-Shun',
        'E2C56DB5-DFFB-48D2-B060-D0F5A7100000': 'Holy-Jin',
      };

      String uuidUpper = uuid.toUpperCase();
      if (holyUuids.containsKey(uuidUpper)) {
        finalDeviceName = holyUuids[uuidUpper]!;
      }
    }

    // Si el nombre original ya contiene "Holy", mantenerlo
    if (deviceName.toLowerCase().contains('holy')) {
      finalDeviceName = deviceName;

      // Para dispositivos Holy, asegurar que tengan datos mínimos para mostrar
      if (uuid == null) {
        // Generar un UUID dummy basado en la MAC para que tenga información que mostrar
        String macHex =
            deviceId.replaceAll(':', '').toLowerCase().padRight(32, '0');
        if (macHex.length >= 32) {
          uuid =
              '${macHex.substring(0, 8)}-${macHex.substring(8, 12)}-${macHex.substring(12, 16)}-${macHex.substring(16, 20)}-${macHex.substring(20, 32)}';
        }
      }
      major ??= 100;
      minor ??= 200;
      txPower ??= -59;
    }
    final newDevice = SimpleBeaconDevice(
      deviceId: deviceId,
      name: finalDeviceName,
      rssi: device.rssi,
      lastSeen: DateTime.now(),
      uuid: uuid,
      major: major,
      minor: minor,
      txPower: txPower,
    );

    // Debug log para verificar detección
    if (uuid != null || finalDeviceName.toLowerCase().contains('holy')) {
      print('🔍 Beacon detectado:');
      print('  📱 Nombre original: $deviceName');
      print('  🏷️  Nombre final: $finalDeviceName');
      print('  🆔 MAC: $deviceId');
      print('  📡 UUID: $uuid');
      print('  🏷️  Major: $major, Minor: $minor');
      print('  📶 RSSI: ${device.rssi} dBm, TX Power: $txPower dBm');
      print('  ✅ Es Holy: ${_isHolyDevice(newDevice)}');
      print('');
    }

    // Siempre actualizar los datos internos pero solo setState cada 500ms
    if (_devices.containsKey(deviceId)) {
      _devices[deviceId] = _devices[deviceId]!.copyWith(
        rssi: device.rssi,
        lastSeen: DateTime.now(),
      );
    } else {
      _devices[deviceId] = newDevice;
    }

    // Solo actualizar UI cada 500ms para evitar que se mueva muy rápido
    if (shouldUpdate) {
      _lastUpdate = now;
      setState(() {
        // Los cambios ya se aplicaron arriba
      });
    }
  }

  String _formatUuid(Uint8List bytes) {
    final buffer = StringBuffer();
    for (int i = 0; i < bytes.length; i++) {
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        buffer.write('-');
      }
    }
    return buffer.toString().toUpperCase();
  }

  bool _isHolyDevice(SimpleBeaconDevice device) {
    // Verificar por nombre primero (más confiable)
    bool isHolyByName = device.name.toLowerCase().contains('holy');

    if (isHolyByName) return true;

    // Verificar por UUID si está disponible
    if (device.uuid == null) return false;

    const holyUuids = [
      'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy-Shun
      'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy-Jin
    ];

    return holyUuids.contains(device.uuid!.toUpperCase());
  }

  List<SimpleBeaconDevice> get _filteredDevices {
    final devices = _devices.values.toList();

    // Ordenar: primero los Holy (verificados), luego por tiempo
    devices.sort((a, b) {
      final bool aIsHoly = _isHolyDevice(a);
      final bool bIsHoly = _isHolyDevice(b);

      // Si uno es Holy y el otro no, el Holy va primero
      if (aIsHoly && !bIsHoly) return -1;
      if (!aIsHoly && bIsHoly) return 1;

      // Si ambos son Holy o ambos no son Holy, ordenar por tiempo
      return b.lastSeen.compareTo(a.lastSeen);
    });

    if (_searchFilter.isEmpty) {
      return devices;
    }

    return devices
        .where((device) =>
            device.name.toLowerCase().contains(_searchFilter.toLowerCase()) ||
            device.deviceId
                .toLowerCase()
                .contains(_searchFilter.toLowerCase()) ||
            (device.uuid?.toLowerCase().contains(_searchFilter.toLowerCase()) ??
                false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iBeacon Scanner'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda y botón de escaneo
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar dispositivos...',
                      hintStyle: TextStyle(color: Color(0xFF64748B)),
                      prefixIcon: Icon(Icons.search,
                          color: Color(0xFF64748B), size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchFilter = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isScanning
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFDC2626)
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF0F172A),
                                    Color(0xFF334155)
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (_isScanning
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF0F172A))
                                  .withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _toggleScanning,
                          icon: Icon(
                            _isScanning
                                ? Icons.stop_circle_outlined
                                : Icons.radar,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            _isScanning ? 'Detener' : 'Iniciar Escaneo',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _devices.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(
                          Icons.clear_all,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Indicador de escaneo y contador
          if (_isScanning || _filteredDevices.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: Row(
                children: [
                  if (_isScanning) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Escaneando...',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                  ],
                  const Icon(Icons.devices_other,
                      size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredDevices.length} encontrado${_filteredDevices.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Lista de dispositivos
          Expanded(
            child: _filteredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isScanning
                              ? 'Buscando dispositivos...'
                              : 'No se encontraron dispositivos',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (!_isScanning) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Presiona "Iniciar Escaneo" para buscar',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredDevices.length,
                    itemBuilder: (context, index) {
                      return _buildDeviceCard(_filteredDevices[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(SimpleBeaconDevice device) {
    // Verificar si es un dispositivo Holy conocido
    final bool isVerified = _isHolyDevice(device);

    // Definir colores minimalistas
    Color primaryColor;
    Color backgroundColor;

    if (isVerified) {
      if (device.name.contains('Holy-Shun')) {
        primaryColor = const Color(0xFF3B82F6); // Azul elegante
        backgroundColor = const Color(0xFFEFF6FF); // Fondo azul muy suave
      } else {
        primaryColor = const Color(0xFF10B981); // Verde elegante
        backgroundColor = const Color(0xFFECFDF5); // Fondo verde muy suave
      }
    } else {
      primaryColor = const Color(0xFF64748B); // Gris elegante
      backgroundColor = const Color(0xFFF8FAFC); // Fondo gris muy suave
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isVerified ? backgroundColor.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified
              ? primaryColor.withOpacity(0.4)
              : const Color(0xFFE2E8F0),
          width: isVerified ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isVerified
                ? primaryColor.withOpacity(0.15)
                : Colors.black.withOpacity(0.04),
            offset: Offset(0, isVerified ? 6 : 4),
            blurRadius: isVerified ? 25 : 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navegación a detalles
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con nombre y badge
                Row(
                  children: [
                    // Badge de estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: primaryColor.withOpacity(0.3), width: 1),
                      ),
                      child: Text(
                        'iBeacon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'HOLY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Badge RSSI
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getRssiColor(device.rssi),
                            _getRssiColor(device.rssi).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getRssiColor(device.rssi).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.signal_cellular_alt,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${device.rssi} dBm',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Nombre del dispositivo
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 16),

                // Grid de información
                Column(
                  children: [
                    // Primera fila: MAC
                    _buildMinimalInfoRow(
                      icon: Icons.fingerprint,
                      label: 'MAC',
                      value: _formatMacAddress(device.deviceId),
                      primaryColor: primaryColor,
                    ),

                    if (device.uuid != null) ...[
                      const SizedBox(height: 12),
                      _buildMinimalInfoRow(
                        icon: Icons.qr_code_2,
                        label: 'UUID',
                        value: device.uuid!.toUpperCase(),
                        primaryColor: primaryColor,
                        isMonospace: true,
                      ),
                    ],

                    if (device.major != null && device.minor != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMinimalInfoRow(
                              icon: Icons.tag,
                              label: 'Major',
                              value: '${device.major}',
                              primaryColor: primaryColor,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildMinimalInfoRow(
                              icon: Icons.label,
                              label: 'Minor',
                              value: '${device.minor}',
                              primaryColor: primaryColor,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (device.txPower != null) ...[
                      const SizedBox(height: 12),
                      _buildMinimalInfoRow(
                        icon: Icons.wifi_tethering,
                        label: 'TX Power',
                        value: '${device.txPower} dBm',
                        primaryColor: primaryColor,
                      ),
                    ],

                    const SizedBox(height: 12),
                    _buildMinimalInfoRow(
                      icon: Icons.schedule,
                      label: 'Visto',
                      value: _formatRelative(device.lastSeen),
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color primaryColor,
    bool compact = false,
    bool isMonospace = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 6 : 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: compact ? 14 : 16,
            color: primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMacAddress(String mac) {
    // Formatear MAC con dos puntos cada 2 caracteres
    if (mac.length >= 12) {
      return mac.toUpperCase().replaceAllMapped(
            RegExp(r'(.{2})(?=.)'),
            (match) => '${match.group(1)}:',
          );
    }
    return mac.toUpperCase();
  }

  Color _getRssiColor(int rssi) {
    if (rssi > -50) return const Color(0xFF10B981);
    if (rssi > -70) return const Color(0xFFEAB308);
    return const Color(0xFFEF4444);
  }

  int _signedInt8(int byte) => byte > 127 ? byte - 256 : byte;

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 5) return 'ahora';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scanSubscription?.cancel();
    super.dispose();
  }
}
