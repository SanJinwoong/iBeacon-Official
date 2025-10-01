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
}
```

## 🔗 **Enlaces**

- **GitHub**: https://github.com/SanJinwoong/holy-beacon-sdk
- **pub.dev**: https://pub.dev/packages/holy_beacon_sdk
- **Documentación**: https://github.com/SanJinwoong/holy-beacon-sdk/wiki
- **Issues**: https://github.com/SanJinwoong/iBeacon-Official/issues

---

**Desarrollado con ❤️ por el equipo Holy Beacon SDK**