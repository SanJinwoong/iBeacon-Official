# Contribuyendo al Holy Beacon SDK

## 🎯 Cómo contribuir

### 📋 Para reportar bugs
1. Abre un issue con el template de bug
2. Incluye información del dispositivo y versión de Flutter
3. Proporciona pasos para reproducir el problema

### ✨ Para solicitar nuevas características
1. Abre un issue con el template de feature request
2. Describe el caso de uso y beneficios
3. Proporciona ejemplos de la API propuesta

### 🔧 Para contribuir código
1. Fork el repositorio
2. Crea una rama descriptiva: `feature/nueva-funcionalidad`
3. Haz commit con mensajes claros
4. Abre un Pull Request

## 📝 Estándares de código

- Usa `dart format` antes de hacer commit
- Ejecuta `flutter analyze` para verificar warnings
- Asegúrate que los tests existentes pasen
- Añade tests para nuevas funcionalidades

## 🧪 Testing

```bash
cd holy_beacon_sdk
flutter test
```

## 📦 Publicación

Solo los maintainers pueden publicar nuevas versiones a pub.dev:

```bash
flutter pub publish
```