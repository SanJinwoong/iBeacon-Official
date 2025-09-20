Instrucciones rápidas build / firma Android

1. Debug rápido:
   flutter run

2. Release APK:
   flutter build apk --release

3. Firma (crear keystore una sola vez):
   keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

   (Windows PowerShell) ejemplo:
   keytool -genkey -v -keystore .\my-release-key.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

4. Configurar en android/key.properties:
   storePassword=XXXX
   keyPassword=XXXX
   keyAlias=upload
   storeFile=../my-release-key.jks

5. Editar build.gradle para usar signingConfig release (pendiente manual aquí por simplicidad).
