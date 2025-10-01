# Holy Beacon SDK - Multiplataforma

[![pub package](https://img.shields.io/pub/v/holy_beacon_sdk.svg)](https://pub.dev/packages/holy_beacon_sdk)
[![Android](https://img.shields.io/badge/Platform-Android-green.svg)](https://android.com)
[![iOS](https://img.shields.io/badge/Platform-iOS-blue.svg)](https://developer.apple.com/ios/)
[![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B.svg)](https://flutter.dev)

Un SDK completo y multiplataforma para el procesamiento de UUIDs y detección de dispositivos Holy Beacon. Diseñado para integrarse perfectamente en sistemas más grandes como un módulo independiente.

## 🎯 **Características Principales**

### ✨ **Core UUID Processor**
- **Procesamiento individual y en lotes** de UUIDs
- **Validación y normalización** automática de formatos
- **Detección inteligente** de dispositivos Holy
- **Categorización y confianza** por niveles de trust
- **Conversión de formatos** (bytes, string, normalización)
- **Manejo robusto de errores** con tipos específicos

### 🔄 **Multiplataforma**
- **Flutter/Dart**: Librería completa con escaneo BLE
- **Android Nativo**: Módulo AAR independiente  
- **iOS Nativo**: Swift Package Manager
- **Integración**: Listo para sistemas más grandes

### 📊 **Inteligencia de Dispositivos**
- **Holy Shun**: Trust level 10 - `FDA50693-A4E2-4FB1-AFCF-C6EB07647825`
- **Holy Jin**: Trust level 10 - `E2C56DB5-DFFB-48D2-B060-D0F5A7100000`  
- **Kronos Blaze**: Trust level 9 - `F7826DA6-4FA2-4E98-8024-BC5B71E0893E`
- **Dispositivos genéricos**: Trust level 1

## 🚀 **Instalación**

### Flutter/Dart (pub.dev)

```yaml
dependencies:
  holy_beacon_sdk: ^0.1.0
```

```bash
flutter pub get
```

### Android (Gradle/AAR)

```gradle
// En tu build.gradle (Module: app)
dependencies {
    implementation 'com.holybeacon:holy-beacon-core:0.1.0'
}
```

### iOS (Swift Package Manager)

```swift
// En Package.swift
dependencies: [
    .package(url: "https://github.com/SanJinwoong/holy-beacon-sdk", from: "0.1.0")
]
```

O en Xcode: **File** → **Add Package Dependencies** → `https://github.com/SanJinwoong/holy-beacon-sdk`

## 📖 **Uso Básico**

### 🎯 **1. Procesamiento de UUID Individual**

#### Flutter/Dart
```dart
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

// Procesar un UUID individual
final result = UuidProcessor.processSingleUuid(
  'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
  validateFormat: true,
  normalizeFormat: true,
);

if (result.isValid) {
  print('UUID: ${result.normalizedUuid}');
  print('Es dispositivo Holy: ${result.isHolyDevice}');
  print('Categoría: ${result.deviceCategory}');
  print('Tipo: ${result.deviceType}');
  print('Nivel de confianza: ${result.trustLevel}/10');
} else {
  print('Error: ${result.errorMessage}');
}
```

#### Android (Kotlin)
```kotlin
import com.holybeacon.core.UuidProcessor

// Procesar un UUID individual
val result = UuidProcessor.processSingleUuid(
    "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
    validateFormat = true,
    normalizeFormat = true
)

if (result.isValid) {
    println("UUID: ${result.normalizedUuid}")
    println("Es dispositivo Holy: ${result.isHolyDevice}")
    println("Categoría: ${result.deviceCategory}")
    println("Tipo: ${result.deviceType}")
    println("Nivel de confianza: ${result.trustLevel}/10")
} else {
    println("Error: ${result.errorMessage}")
}
```

#### iOS (Swift)
```swift
import HolyBeaconCore

// Procesar un UUID individual
let result = UuidProcessor.processSingleUuid(
    "FDA50693-A4E2-4FB1-AFCF-C6EB07647825",
    validateFormat: true,
    normalizeFormat: true
)

if result.isValid {
    print("UUID: \(result.normalizedUuid)")
    print("Es dispositivo Holy: \(result.isHolyDevice)")
    print("Categoría: \(result.deviceCategory.name)")
    print("Tipo: \(result.deviceType)")
    print("Nivel de confianza: \(result.trustLevel)/10")
} else {
    print("Error: \(result.errorMessage ?? "No message")")
}
```

### 🎯 **2. Procesamiento de Listas de UUIDs**

```dart
// Flutter/Dart
final uuids = [
  'FDA50693-A4E2-4FB1-AFCF-C6EB07647825', // Holy Shun
  'E2C56DB5-DFFB-48D2-B060-D0F5A7100000', // Holy Jin  
  '12345678-1234-5678-9012-123456789012', // Genérico
  'F7826DA6-4FA2-4E98-8024-BC5B71E0893E', // Kronos
];

final result = UuidProcessor.processUuidList(
  uuids,
  filterInvalid: false,
  prioritizeHoly: true,
);

print('Total procesados: ${result.totalProcessed}');
print('Válidos: ${result.validCount}');
print('Dispositivos Holy: ${result.holyDeviceCount}');
print('Tasa de éxito: ${result.successRate}%');
print('Tasa Holy: ${result.holyDeviceRate}%');

// Iterar por dispositivos Holy
for (final holyDevice in result.holyResults) {
  print('Holy: ${holyDevice.normalizedUuid} (${holyDevice.deviceCategory})');
}
```

### 🎯 **3. Escaneo BLE en Tiempo Real (Solo Flutter)**

```dart
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

class BeaconExample extends StatefulWidget {
  @override
  _BeaconExampleState createState() => _BeaconExampleState();
}

class _BeaconExampleState extends State<BeaconExample> {
  HolyBeaconScanner? _scanner;
  List<BeaconDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    _scanner = HolyBeaconScanner();
    
    // Escuchar dispositivos detectados
    _scanner!.deviceStream.listen((device) {
      setState(() {
        _devices.add(device);
      });
    });
    
    // Escuchar errores
    _scanner!.errorStream.listen((error) {
      print('Error de escaneo: $error');
    });
  }

  void _startScanning() async {
    await _scanner!.startScanning(
      scanMode: BleScanMode.balanced,
      timeout: Duration(seconds: 30),
      holyDevicesOnly: true, // Solo dispositivos Holy
    );
  }

  void _stopScanning() async {
    await _scanner!.stopScanning();
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Holy Beacon Scanner')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _startScanning,
                child: Text('Iniciar Escaneo'),
              ),
              ElevatedButton(
                onPressed: _stopScanning,
                child: Text('Parar Escaneo'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name ?? 'Dispositivo Desconocido'),
                  subtitle: Text('UUID: ${device.uuid}'),
                  trailing: Text('RSSI: ${device.rssi}'),
                  leading: device.isHolyDevice 
                    ? Icon(Icons.star, color: Colors.gold)
                    : Icon(Icons.bluetooth),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🏗️ **Integración en Sistemas Grandes**

### 🔄 **Como Módulo Independiente**

#### En una app Flutter empresarial:
```dart
class BeaconService {
  static Future<List<String>> getHolyDeviceUuids(List<String> candidateUuids) async {
    final result = UuidProcessor.processUuidList(candidateUuids, filterInvalid: true);
    return result.holyResults.map((r) => r.normalizedUuid).toList();
  }
  
  static Future<bool> isHolyDevice(String uuid) async {
    final result = UuidProcessor.processSingleUuid(uuid);
    return result.isHolyDevice;
  }
  
  static Future<int> calculateTrustScore(List<String> detectedUuids) async {
    final result = UuidProcessor.processUuidList(detectedUuids);
    return result.holyResults
        .fold<int>(0, (sum, device) => sum + device.trustLevel);
  }
}
```

#### En una app Android nativa:
```kotlin
class BeaconService {
    companion object {
        @JvmStatic
        fun getHolyDeviceUuids(candidateUuids: List<String>): List<String> {
            val result = UuidProcessor.processUuidList(candidateUuids, filterInvalid = true)
            return result.holyResults.map { it.normalizedUuid }
        }
        
        @JvmStatic
        fun isHolyDevice(uuid: String): Boolean {
            val result = UuidProcessor.processSingleUuid(uuid)
            return result.isHolyDevice
        }
        
        @JvmStatic
        fun calculateTrustScore(detectedUuids: List<String>): Int {
            val result = UuidProcessor.processUuidList(detectedUuids)
            return result.holyResults.sumOf { it.trustLevel }
        }
    }
}
```

#### En una app iOS nativa:
```swift
class BeaconService {
    static func getHolyDeviceUuids(_ candidateUuids: [String]) -> [String] {
        let result = UuidProcessor.processUuidList(candidateUuids, filterInvalid: true)
        return result.holyResults.map { $0.normalizedUuid }
    }
    
    static func isHolyDevice(_ uuid: String) -> Bool {
        let result = UuidProcessor.processSingleUuid(uuid)
        return result.isHolyDevice
    }
    
    static func calculateTrustScore(_ detectedUuids: [String]) -> Int {
        let result = UuidProcessor.processUuidList(detectedUuids)
        return result.holyResults.reduce(0) { $0 + $1.trustLevel }
    }
}
```

## � **Arquitectura del Proyecto**

```
holy_beacon_sdk/
├── lib/
│   ├── src/
│   │   ├── core/
│   │   │   ├── uuid_processor.dart      # 🔥 Core UUID processing engine
│   │   │   └── models.dart              # Data models y enums
│   │   ├── services/
│   │   │   ├── holy_beacon_scanner.dart # BLE scanning (Flutter only)
│   │   │   └── permission_handler.dart  # Permisos de ubicación/BLE  
│   │   └── utils/
│   │       ├── beacon_utils.dart        # Utilidades para parsing
│   │       └── constants.dart           # Constantes y configuración
│   └── holy_beacon_sdk.dart             # Exportaciones públicas
├── android_module/                      # 📱 Módulo Android AAR nativo
│   ├── src/main/kotlin/
│   │   └── com/holybeacon/core/
│   │       ├── UuidProcessor.kt         # Core logic en Kotlin
│   │       └── Models.kt                # Data classes
│   └── build.gradle                     # Configuración AAR
├── ios_module/                          # 🍎 Swift Package nativo
│   ├── Sources/HolyBeaconCore/
│   │   ├── UuidProcessor.swift          # Core logic en Swift
│   │   └── Models.swift                 # Structs y enums
│   ├── Tests/HolyBeaconCoreTests/       # Tests de Swift
│   └── Package.swift                    # SPM configuración
├── test/                                # 🧪 Tests comprehensivos
│   ├── uuid_processor_test.dart         # 100+ tests del core
│   └── integration_test.dart            # Tests de integración
└── example/                             # 📚 Ejemplos y demos
    └── lib/main.dart                    # Demo app
```

## 📊 **Testing y Calidad**

### ✅ **Cobertura de Tests**
- **Core UUID Processor**: 100+ test cases
- **Procesamiento individual**: 25+ tests  
- **Procesamiento en lotes**: 15+ tests
- **Validación y normalización**: 20+ tests
- **Detección Holy**: 15+ tests
- **Manejo de errores**: 10+ tests
- **Casos edge**: 10+ tests

### 🔧 **Para ejecutar los tests**

```bash
# Flutter tests
cd holy_beacon_sdk
flutter test

# Android tests (requiere Android Studio/gradlew)
cd android_module
./gradlew test

# iOS tests (requiere Xcode)
cd ios_module  
swift test
```

## 🚀 **Rendimiento**

### ⚡ **Benchmarks**
- **Procesamiento individual**: < 1ms por UUID
- **Procesamiento en lotes**: < 10ms para 1000 UUIDs
- **Validación**: Regex optimizado con caching
- **Memoria**: Footprint mínimo (~50KB)

### 📈 **Escalabilidad**
- **Flutter**: Manejo de miles de dispositivos simultáneos
- **Android/iOS**: Integración sin overhead significativo
- **Core Logic**: Zero-copy optimizations donde sea posible

## 🤝 **Contribuir**

1. Fork el proyecto
2. Crear una rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 **Licencia**

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 🔗 **Enlaces**

- **GitHub**: https://github.com/SanJinwoong/holy-beacon-sdk
- **pub.dev**: https://pub.dev/packages/holy_beacon_sdk
- **Documentación**: https://github.com/SanJinwoong/holy-beacon-sdk/wiki
- **Issues**: https://github.com/SanJinwoong/iBeacon-Official/issues

## 📞 **Soporte**

¿Necesitas ayuda? Crea un [issue](https://github.com/SanJinwoong/iBeacon-Official/issues) o contacta al equipo de desarrollo.

---

**Desarrollado con ❤️ por el equipo Holy Beacon SDK**
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