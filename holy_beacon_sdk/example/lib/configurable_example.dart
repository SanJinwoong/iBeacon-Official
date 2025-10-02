import 'package:flutter/material.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

/// Ejemplo que demuestra la configurabilidad completa del Holy Beacon SDK
///
/// Este ejemplo muestra cómo cualquier desarrollador puede:
/// 1. Registrar sus propios UUIDs de beacon
/// 2. Recibir notificaciones cuando se detecten sus beacons
/// 3. Gestionar perfiles de beacon de forma persistente
/// 4. Limpiar configuraciones cuando sea necesario
///
/// El SDK no está limitado a dispositivos Holy - es completamente configurable
/// para cualquier UUID de beacon que el desarrollador desee detectar.
void main() {
  runApp(const ConfigurableBeaconApp());
}

class ConfigurableBeaconApp extends StatelessWidget {
  const ConfigurableBeaconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Configurable Beacon Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const BeaconConfigurationScreen(),
    );
  }
}

class BeaconConfigurationScreen extends StatefulWidget {
  const BeaconConfigurationScreen({super.key});

  @override
  State<BeaconConfigurationScreen> createState() =>
      _BeaconConfigurationScreenState();
}

class _BeaconConfigurationScreenState extends State<BeaconConfigurationScreen> {
  final HolyBeaconScanner _scanner = HolyBeaconScanner();
  final BeaconProfileManager _profileManager = BeaconProfileManager();
  final TextEditingController _uuidController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  List<BeaconProfile> _registeredProfiles = [];
  List<BeaconDevice> _detectedBeacons = [];
  bool _isScanning = false;
  String _lastDetectedBeacon = 'Ninguno detectado aún';

  @override
  void initState() {
    super.initState();
    _loadRegisteredProfiles();
    _setupBeaconDetection();
  }

  void _loadRegisteredProfiles() async {
    final profiles = await _profileManager.getRegisteredProfiles();
    setState(() {
      _registeredProfiles = profiles;
    });
  }

  void _setupBeaconDetection() {
    // Escuchar detecciones individuales de beacon
    _scanner.onBeaconDetected.listen((beacon) {
      setState(() {
        _lastDetectedBeacon =
            'UUID: ${beacon.uuid}\nNombre: ${beacon.name}\nRSSI: ${beacon.rssi}';
      });

      // Mostrar notificación cuando se detecte un beacon registrado
      if (beacon.isVerifiedByProfile) {
        _showBeaconDetectedSnackBar(beacon);
      }
    });

    // Escuchar la lista completa de dispositivos
    _scanner.devices.listen((devices) {
      setState(() {
        _detectedBeacons = devices;
      });
    });
  }

  void _showBeaconDetectedSnackBar(BeaconDevice beacon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '¡Beacon registrado detectado!\n${beacon.name} (${beacon.uuid})'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _registerNewBeacon() async {
    final uuid = _uuidController.text.trim();
    final name = _nameController.text.trim();

    if (uuid.isEmpty || name.isEmpty) {
      _showErrorSnackBar('Por favor ingresa tanto el UUID como el nombre');
      return;
    }

    try {
      // Registrar el beacon en el perfil manager
      await _profileManager.registerVerifiedBeacon(uuid, name);

      // También registrar en el scanner para detección inmediata
      await _scanner.registerVerifiedBeacon(uuid, name);

      // Recargar la lista de perfiles
      _loadRegisteredProfiles();

      // Limpiar los campos
      _uuidController.clear();
      _nameController.clear();

      _showSuccessSnackBar('Beacon registrado exitosamente: $name');
    } catch (e) {
      _showErrorSnackBar('Error al registrar beacon: $e');
    }
  }

  void _removeBeacon(String uuid) async {
    try {
      await _profileManager.unregisterVerifiedBeacon(uuid);
      await _scanner.unregisterVerifiedBeacon(uuid);
      _loadRegisteredProfiles();
      _showSuccessSnackBar('Beacon eliminado exitosamente');
    } catch (e) {
      _showErrorSnackBar('Error al eliminar beacon: $e');
    }
  }

  void _clearAllProfiles() async {
    try {
      await _profileManager.clearDefaultProfiles();
      await _scanner.clearDefaultProfiles();
      _loadRegisteredProfiles();
      _showSuccessSnackBar('Todos los perfiles eliminados');
    } catch (e) {
      _showErrorSnackBar('Error al limpiar perfiles: $e');
    }
  }

  void _toggleScanning() async {
    if (_isScanning) {
      await _scanner.stopScanning();
      setState(() {
        _isScanning = false;
        _detectedBeacons.clear();
      });
    } else {
      await _scanner.startScanning();
      setState(() {
        _isScanning = true;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beacon Scanner Configurable'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de registro de nuevo beacon
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registrar Nuevo Beacon',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _uuidController,
                      decoration: const InputDecoration(
                        labelText: 'UUID del Beacon',
                        hintText: 'ej: FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Beacon',
                        hintText: 'ej: Mi Beacon Personalizado',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _registerNewBeacon,
                          child: const Text('Registrar Beacon'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _clearAllProfiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Limpiar Todo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de control de escaneo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Control de Escaneo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _toggleScanning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isScanning ? Colors.red : Colors.green,
                          ),
                          child: Text(_isScanning
                              ? 'Detener Escaneo'
                              : 'Iniciar Escaneo'),
                        ),
                        const SizedBox(width: 12),
                        Chip(
                          label:
                              Text(_isScanning ? 'Escaneando...' : 'Detenido'),
                          backgroundColor: _isScanning
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Último beacon detectado:'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _lastDetectedBeacon,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de beacons registrados
            const Text(
              'Beacons Registrados:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _registeredProfiles.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay beacons registrados.\n\nRegistra un UUID arriba para comenzar a detectar tus propios beacons.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _registeredProfiles.length,
                      itemBuilder: (context, index) {
                        final profile = _registeredProfiles[index];
                        final isDetected = _detectedBeacons.any((beacon) =>
                            beacon.uuid.toLowerCase() ==
                            profile.uuid.toLowerCase());

                        return Card(
                          color:
                              isDetected ? Colors.green.withOpacity(0.1) : null,
                          child: ListTile(
                            leading: Icon(
                              isDetected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth,
                              color: isDetected ? Colors.green : Colors.grey,
                            ),
                            title: Text(profile.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('UUID: ${profile.uuid}'),
                                if (isDetected)
                                  const Text(
                                    '✓ Detectado actualmente',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeBeacon(profile.uuid),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    _uuidController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
