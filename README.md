# 📡 iBeacon Official Repository

Repositorio oficial para implementaciones de detección de iBeacons y Beacons Eddystone.

## 📦 Proyectos

### 🔥 Holy Beacon SDK
**SDK configurable para Flutter** - Ahora disponible en [pub.dev](https://pub.dev/packages/holy_beacon_sdk)

- **Versión actual**: v0.1.2
- **Ubicación**: `/holy_beacon_sdk/`
- **Pub.dev**: [holy_beacon_sdk](https://pub.dev/packages/holy_beacon_sdk)

```yaml
dependencies:
  holy_beacon_sdk: ^0.1.2
```

### 📱 iBeacon Scanner App
Aplicación Flutter moderna para escanear y detectar dispositivos iBeacon con diseño minimalista y priorización de dispositivos Holy.

## ✨ Características

### Holy Beacon SDK:
- ✅ **Totalmente configurable**: No limitado a dispositivos Holy específicos
- ✅ **Gestión persistente**: Registra cualquier UUID de beacon
- ✅ **Stream reactivo**: Callbacks en tiempo real para detecciones
- ✅ **Compatibilidad completa**: Android/iOS con Flutter Reactive BLE
- ✅ **APIs flexibles**: registerVerifiedBeacon, unregisterVerifiedBeacon, etc.

### iBeacon Scanner App:
- **Escaneo BLE en tiempo real**: Detecta automáticamente dispositivos iBeacon cercanos
- **Priorización de dispositivos Holy**: Los dispositivos Holy-IOT aparecen siempre al inicio de la lista
- **Interfaz minimalista**: Diseño elegante con Material 3 y colores modernos
- **Información detallada de beacons**: Muestra UUID, Major, Minor, RSSI y distancia estimada
- **Badges de verificación**: Identificación visual de dispositivos Holy con iconos especiales
- **Gestión de permisos**: Manejo automático de permisos de Bluetooth y ubicación

## 🛠️ Tecnologías Utilizadas

- **Flutter 3.35.1**: Framework principal
- **flutter_reactive_ble**: Para escaneo BLE
- **permission_handler**: Gestión de permisos Android
- **device_info_plus**: Información del dispositivo
- **Material 3**: Diseño moderno y accesible

## 📱 Capturas de Pantalla

La aplicación presenta:
- Lista de dispositivos con información detallada
- Badges de verificación para dispositivos Holy
- Diseño responsive y moderno
- Indicadores de señal y distancia

## 🚀 Instalación

1. **Clona el repositorio**:
   ```bash
   git clone https://github.com/tu-usuario/ibeacon.git
   cd ibeacon
   ```

2. **Instala las dependencias**:
   ```bash
   flutter pub get
   ```

3. **Ejecuta la aplicación**:
   ```bash
   flutter run
   ```

## 📋 Requisitos

- Flutter SDK 3.0 o superior
- Android SDK 21 o superior
- Dispositivo con Bluetooth 4.0+
- Permisos de ubicación y Bluetooth

## 🔧 Configuración

### Android
- Permisos automáticos para Bluetooth y ubicación
- Compatible con Android 5.0 (API 21) o superior

### iOS
- Configuración automática de Info.plist
- Compatible con iOS 9.0 o superior

## 🎯 Funcionalidades Principales

### Detección de Dispositivos Holy
- Priorización automática de dispositivos "Holy-IOT"
- Badges de verificación visual
- Información completa de beacon

### Interfaz de Usuario
- Diseño minimalista con colores modernos
- Cards con información detallada
- Indicadores de distancia y señal
- Actualización en tiempo real

## 📖 Uso

1. **Abre la aplicación**
2. **Permite los permisos** de Bluetooth y ubicación
3. **Los dispositivos iBeacon** aparecerán automáticamente
4. **Los dispositivos Holy** se mostrarán al inicio con badges especiales
5. **Toca un dispositivo** para ver información detallada

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

- **Tu Nombre** - *Desarrollo inicial* - [tu-usuario](https://github.com/tu-usuario)

## 🙏 Agradecimientos

- Flutter team por el increíble framework
- Comunidad de desarrolladores Flutter
- Contribuidores de los paquetes utilizados
