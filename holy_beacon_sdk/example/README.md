# Ejemplo de Configuración Dinámica - Holy Beacon SDK

Este ejemplo demuestra cómo **cualquier desarrollador** puede usar el Holy Beacon SDK para detectar sus propios beacons, no solo los dispositivos Holy predeterminados.

## 🎯 **Características Demostradas**

- ✅ **Registro dinámico de UUIDs**: Registra cualquier UUID de beacon que necesites
- ✅ **Almacenamiento persistente**: Los perfiles se mantienen entre sesiones  
- ✅ **Callbacks individuales**: Recibe notificaciones cuando se detecte tu beacon específico
- ✅ **Gestión completa**: Agregar, eliminar, limpiar perfiles dinámicamente
- ✅ **No limitado a Holy**: Funciona con cualquier beacon iBeacon/Eddystone

## 🚀 **Cómo Ejecutar**

```bash
cd example
flutter pub get
flutter run
```

## 📱 **Funcionalidades de la App**

### Registrar tu propio beacon
1. Ingresa el UUID de tu beacon (ej: `AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE`)
2. Ingresa un nombre descriptivo
3. Presiona "Registrar Beacon"
4. ¡Tu beacon ahora se detectará automáticamente!

### Control de escaneo
- **Iniciar/Detener escaneo** de beacons
- **Ver último beacon detectado** con detalles completos
- **Estado visual** del proceso de escaneo

### Gestión de perfiles
- **Ver todos los beacons registrados** con estado de detección
- **Eliminar beacons específicos** individualmente  
- **Limpiar todos los perfiles** (incluidos los predeterminados)
- **Indicadores visuales** cuando tus beacons están activos

## 💡 **Casos de Uso Reales**

### Para Desarrolladores de Apps
```dart
// Registrar beacons de tu sistema
await profileManager.registerVerifiedBeacon(
  'TU-UUID-AQUI',
  'Beacon de Mi Sistema'
);

// Escuchar solo TUS beacons
scanner.onBeaconDetected.listen((beacon) {
  if (beacon.isVerifiedByProfile) {
    // Solo se ejecuta para beacons que registraste
    processMyBeacon(beacon);
  }
});
```

### Para Empresas
- **Tiendas**: Registrar beacons de productos específicos
- **Oficinas**: Detectar beacons de salas de reuniones  
- **Eventos**: Rastrear ubicaciones de áreas específicas
- **Logística**: Seguimiento de contenedores o equipos

### Para IoT y Automatización
- **Smart Home**: Detectar beacons de dispositivos domésticos
- **Industrial**: Monitoreo de maquinaria con beacons
- **Hospitalidad**: Check-in automático en hoteles
- **Seguridad**: Detección de llaves o badges de acceso

## 🎛️ **APIs Clave Utilizadas**

```dart
// Registro persistente
await profileManager.registerVerifiedBeacon(uuid, name);

// Callbacks individuales  
scanner.onBeaconDetected.listen((beacon) { });

// Gestión de perfiles
await profileManager.unregisterVerifiedBeacon(uuid);
await profileManager.clearVerifiedBeacons();

// Verificación en tiempo real
final isVerified = profileManager.isVerifiedBeacon(uuid);
```

## 🔧 **Configuración de Desarrollo**

Para integrar en tu propia app:

```yaml
dependencies:
  holy_beacon_sdk: ^0.1.0
  shared_preferences: ^2.3.3  # Para persistencia
```

```dart
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';

// Inicializar
final scanner = HolyBeaconScanner();
final profileManager = BeaconProfileManager();

// ¡Listo para registrar tus beacons!
```

---

> **💡 Nota**: Este SDK es completamente configurable y **no está limitado a dispositivos Holy**. Los UUIDs Holy incluidos son solo ejemplos predeterminados que se pueden limpiar fácilmente.