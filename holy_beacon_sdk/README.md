# Holy Beacon SDK

[![pub package](https://img.shields.io/pub/v/holy_beacon_sdk.svg)](https://pub.dev/packages/holy_beacon_sdk)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Una librería Flutter completa para el escaneo y detección de beacons iBeacon y Eddystone con priorización de dispositivos Holy.

## ✨ Características

- 🔍 **Escaneo BLE en tiempo real** - Detecta automáticamente dispositivos iBeacon y Eddystone
- 🏆 **Priorización Holy** - Los dispositivos Holy-IOT aparecen siempre al inicio
- 🎯 **Filtrado avanzado** - Sistema de whitelist configurable
- 📱 **Multiplataforma** - Compatible con Android e iOS
- 🔐 **Gestión de permisos** - Manejo automático de permisos BLE y ubicación
- 🛠️ **Fácil integración** - API simple y documentada
- 🔄 **Actualizaciones en tiempo real** - Streams reactivos para UI
- 📊 **Estadísticas** - Métricas detalladas de escaneo

## 🚀 Instalación

Agrega la dependencia a tu `pubspec.yaml`:

```yaml
dependencies:
  holy_beacon_sdk: ^1.0.0
```

Luego ejecuta:

```bash
flutter pub get
```

## 📋 Configuración

### Android

Agrega los permisos necesarios en `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Permisos Bluetooth legacy (Android 11 y anteriores) -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />

<!-- Permisos Bluetooth granulares (Android 12+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Permisos de ubicación (requeridos para BLE) -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Características requeridas -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
<uses-feature android:name="android.hardware.bluetooth" android:required="true" />
```

### iOS

Agrega las descripciones de permisos en `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Esta aplicación usa Bluetooth para detectar dispositivos beacon cercanos.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Esta aplicación usa Bluetooth para detectar dispositivos beacon cercanos.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a la ubicación para detectar beacons BLE.</string>
```

## 💡 Uso Básico

### Ejemplo Simple

```dart
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

class MyBeaconScanner extends StatefulWidget {
  @override
  _MyBeaconScannerState createState() => _MyBeaconScannerState();
}

class _MyBeaconScannerState extends State<MyBeaconScanner> {
  final HolyBeaconScanner scanner = HolyBeaconScanner();
  List<BeaconDevice> devices = [];

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    // Configurar el scanner
    await scanner.initialize(
      config: BeaconScanConfig.holyOptimized(),
      whitelist: BeaconWhitelist.allowAll(),
    );

    // Escuchar dispositivos detectados
    scanner.devices.listen((deviceList) {
      setState(() {
        devices = deviceList;
      });
    });

    // Iniciar escaneo
    await scanner.startScanning();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return ListTile(
          title: Text(device.name),
          subtitle: Text('RSSI: ${device.rssi} dBm'),
          trailing: device.isHolyDevice 
            ? Icon(Icons.verified, color: Colors.blue)
            : null,
        );
      },
    );
  }

  @override
  void dispose() {
    scanner.dispose();
    super.dispose();
  }
}
```

### Configuraciones Avanzadas

```dart
// Configuración optimizada para dispositivos Holy
final config = BeaconScanConfig(
  scanDuration: Duration(seconds: 30),
  minRssi: -80,
  prioritizeHolyDevices: true,
  enableDebugLogs: true,
);

// Whitelist solo para dispositivos Holy
final whitelist = BeaconWhitelist.holyDevicesOnly();

// Inicializar con configuraciones personalizadas
await scanner.initialize(config: config, whitelist: whitelist);
```

### Filtrado por Protocolo

```dart
// Obtener solo dispositivos iBeacon
final ibeacons = scanner.getDevicesByProtocol(BeaconProtocol.ibeacon);

// Obtener solo dispositivos Holy
final holyDevices = scanner.getHolyDevices();

// Estadísticas de escaneo
final stats = scanner.getStats();
print('Total: ${stats.totalDevices}, Holy: ${stats.holyDevices}');
```

## 🎯 Modelos de Datos

### BeaconDevice

```dart
class BeaconDevice {
  final String deviceId;      // MAC address o identificador
  final String name;          // Nombre del dispositivo
  final int rssi;            // Fuerza de señal en dBm
  final String uuid;         // UUID del beacon
  final int major;           // Valor Major (iBeacon)
  final int minor;           // Valor Minor (iBeacon)
  final BeaconProtocol protocol;  // Tipo de protocolo
  final DateTime lastSeen;   // Última vez detectado
  final bool verified;       // Si está verificado
  
  // Propiedades calculadas
  bool get isHolyDevice;           // Es dispositivo Holy
  int get signalStrengthPercent;   // Porcentaje de señal
  String get estimatedDistance;    // Distancia estimada
}
```

### BeaconScanConfig

```dart
class BeaconScanConfig {
  final Duration? scanDuration;        // Duración del escaneo
  final int? minRssi;                 // RSSI mínimo
  final bool prioritizeHolyDevices;   // Priorizar dispositivos Holy
  final bool enableDebugLogs;         // Habilitar logs debug
  
  // Configuraciones predefinidas
  factory BeaconScanConfig.holyOptimized();
  factory BeaconScanConfig.continuous();
}
```

### BeaconWhitelist

```dart
class BeaconWhitelist {
  final Set<String> allowedUuids;     // UUIDs permitidos
  final Set<String> allowedNames;     // Nombres permitidos
  final bool allowUnknown;            // Permitir desconocidos
  
  // Whitelists predefinidas
  factory BeaconWhitelist.holyDevicesOnly();
  factory BeaconWhitelist.allowAll();
  factory BeaconWhitelist.uuidsOnly(Set<String> uuids);
}
```

## 🔧 API Completa

### HolyBeaconScanner

```dart
// Inicialización
await scanner.initialize(config: config, whitelist: whitelist);

// Control de escaneo
await scanner.startScanning(config: customConfig);
await scanner.stopScanning();

// Streams
Stream<List<BeaconDevice>> get devices;
Stream<String> get status;
Stream<HolyBeaconError> get errors;

// Estado
bool get isScanning;
BeaconScanStats getStats();

// Filtrado
List<BeaconDevice> getDevicesByProtocol(BeaconProtocol protocol);
List<BeaconDevice> getHolyDevices();

// Configuración
void setWhitelist(BeaconWhitelist whitelist);
void clearDevices();

// Permisos
Future<bool> requestPermissions();

// Cleanup
void dispose();
```

### PermissionManager

```dart
final permissionManager = PermissionManager();

// Solicitar permisos
final hasPermissions = await permissionManager.requestBeaconPermissions();

// Verificar estado
final status = await permissionManager.checkPermissionStatus();
print('Todos otorgados: ${status.allGranted}');

// Abrir configuración
await permissionManager.openAppSettings();
```

### BeaconUtils

```dart
// Utilidades de señal
final percentage = BeaconUtils.rssiToPercentage(-65);
final quality = BeaconUtils.getSignalQuality(-65);

// Filtrado y ordenamiento
final filtered = BeaconUtils.filterByRssi(devices, -80);
final sorted = BeaconUtils.sortDevicesWithHolyPriority(devices);

// Estadísticas
final stats = BeaconUtils.generateStats(devices);
```

## 🎨 Ejemplos de Integración

### Android Nativo (Gradle)

```gradle
dependencies {
    implementation 'com.holybeacon:sdk:1.0.0'
}
```

```kotlin
val scanner = HolyBeaconScanner()
scanner.startScanning { devices ->
    devices.forEach { device ->
        println("Dispositivo: ${device.name} - ${device.uuid}")
    }
}
```

### iOS (Swift Package Manager)

```swift
.package(url: "https://github.com/SanJinwoong/holy-beacon-sdk-ios", from: "1.0.0")
```

```swift
import HolyBeaconSDK

let scanner = HolyBeaconScanner()
scanner.startScanning { devices in
    for device in devices {
        print("Dispositivo: \(device.name) - \(device.uuid)")
    }
}
```

## 🐛 Manejo de Errores

```dart
scanner.errors.listen((error) {
  switch (error.type) {
    case HolyBeaconErrorType.permissions:
      // Manejar errores de permisos
      _showPermissionDialog();
      break;
    case HolyBeaconErrorType.bluetooth:
      // Manejar errores de Bluetooth
      _showBluetoothDialog();
      break;
    case HolyBeaconErrorType.scanning:
      // Manejar errores de escaneo
      _showScanErrorDialog(error.message);
      break;
    default:
      print('Error desconocido: ${error.message}');
  }
});
```

## 📊 Mejores Prácticas

### 1. Optimización de Batería

```dart
// Escaneo por períodos limitados
final config = BeaconScanConfig(
  scanDuration: Duration(seconds: 30),
  minRssi: -80, // Filtrar dispositivos lejanos
);

// Detener escaneo cuando no es necesario
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    scanner.stopScanning();
  }
}
```

### 2. Gestión de Memoria

```dart
// Limpiar dispositivos antiguos periódicamente
Timer.periodic(Duration(minutes: 1), (timer) {
  final oldDevices = devices.where((device) {
    final age = DateTime.now().difference(device.lastSeen);
    return age > Duration(minutes: 2);
  }).toList();
  
  // Remover dispositivos antiguos
  devices.removeWhere((device) => oldDevices.contains(device));
});
```

### 3. UI Responsiva

```dart
// Throttling de actualizaciones UI
StreamSubscription? _deviceSubscription;

void _startListening() {
  _deviceSubscription = scanner.devices
    .throttleTime(Duration(milliseconds: 500)) // Limitar actualizaciones
    .listen((devices) {
      if (mounted) {
        setState(() {
          this.devices = devices;
        });
      }
    });
}
```

## 🔍 Troubleshooting

### Problemas Comunes

1. **No se detectan dispositivos**
   - Verificar permisos de Bluetooth y ubicación
   - Confirmar que Bluetooth está habilitado
   - Verificar que el dispositivo beacon esté transmitiendo

2. **Permisos denegados**
   - Usar `PermissionManager` para solicitar permisos
   - Guiar al usuario a configuración manual si es necesario

3. **Rendimiento lento**
   - Ajustar `minRssi` para filtrar dispositivos lejanos
   - Usar `scanDuration` para limitar tiempo de escaneo
   - Implementar throttling en actualizaciones UI

### Debug

```dart
// Habilitar logs detallados
final config = BeaconScanConfig(
  enableDebugLogs: true,
);

// Monitorear estado del scanner
scanner.status.listen((status) {
  print('Scanner status: $status');
});

// Estadísticas de rendimiento
final stats = scanner.getStats();
print('Performance: ${stats.toString()}');
```

## 📖 Documentación Adicional

- [API Reference](https://pub.dev/documentation/holy_beacon_sdk/latest/)
- [Ejemplos Completos](https://github.com/SanJinwoong/holy-beacon-sdk/tree/main/example)
- [Guía de Integración Android](docs/android-integration.md)
- [Guía de Integración iOS](docs/ios-integration.md)

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -am 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Crea un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

## 🙏 Agradecimientos

- Flutter team por el increíble framework
- Comunidad de desarrolladores Flutter
- Contribuidores de packages de Bluetooth
- Holy devices team por el hardware de pruebas

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/SanJinwoong/holy-beacon-sdk/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/SanJinwoong/holy-beacon-sdk/discussions)
- **Email**: soporte@holybeacon.com

---

**Holy Beacon SDK** - Llevando la detección de beacons al siguiente nivel 🚀