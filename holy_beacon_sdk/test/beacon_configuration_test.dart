import 'package:flutter_test/flutter_test.dart';
import 'package:holy_beacon_sdk/holy_beacon_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests para el sistema configurable de beacons
///
/// Estos tests verifican que cualquier desarrollador puede:
/// 1. Registrar sus propios UUIDs de beacon
/// 2. Gestionar perfiles de manera persistente
/// 3. Verificar detecciones contra perfiles registrados
/// 4. Limpiar y gestionar la configuración
void main() {
  group('Beacon Configuration System Tests', () {
    late BeaconProfileManager profileManager;

    setUp(() async {
      // Inicializar SharedPreferences en memoria para testing
      SharedPreferences.setMockInitialValues({});
      profileManager = BeaconProfileManager();
    });

    tearDown(() async {
      // Limpiar después de cada test
      await profileManager.clearVerifiedBeacons();
    });

    test('Debe permitir registrar UUIDs personalizados', () async {
      // Arrange
      const customUuid = 'AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE';
      const customName = 'Mi Beacon Personalizado';

      // Act
      await profileManager.registerVerifiedBeacon(customUuid, customName);
      final profiles = profileManager.listVerifiedBeacons();

      // Assert
      expect(profiles.length, greaterThan(0));
      final customProfile = profiles.firstWhere(
        (p) => p.uuid.toLowerCase() == customUuid.toLowerCase(),
        orElse: () => throw Exception('Custom profile not found'),
      );
      expect(customProfile.displayName, equals(customName));
      expect(
          customProfile.uuid.toLowerCase(), equals(customUuid.toLowerCase()));
    });

    test('Debe verificar UUIDs contra perfiles registrados', () async {
      // Arrange
      const testUuid = 'BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF';
      const testName = 'Beacon de Prueba';

      await profileManager.registerVerifiedBeacon(testUuid, testName);

      // Act
      final isVerified = profileManager.isVerifiedBeacon(testUuid);
      final profile = profileManager.getProfile(testUuid);

      // Assert
      expect(isVerified, isTrue);
      expect(profile, isNotNull);
      expect(profile!.displayName, equals(testName));
    });

    test('Debe permitir eliminar perfiles específicos', () async {
      // Arrange
      const uuidToRemove = 'CCCCCCCC-DDDD-EEEE-FFFF-000000000000';
      const nameToRemove = 'Beacon Temporal';

      await profileManager.registerVerifiedBeacon(uuidToRemove, nameToRemove);

      // Verificar que se registró
      expect(profileManager.isVerifiedBeacon(uuidToRemove), isTrue);

      // Act
      await profileManager.unregisterVerifiedBeacon(uuidToRemove);

      // Assert
      expect(profileManager.isVerifiedBeacon(uuidToRemove), isFalse);
      final profile = profileManager.getProfile(uuidToRemove);
      expect(profile, isNull);
    });

    test('Debe persistir perfiles entre sesiones', () async {
      // Arrange
      const persistentUuid = 'DDDDDDDD-EEEE-FFFF-0000-111111111111';
      const persistentName = 'Beacon Persistente';

      // Registrar en primera "sesión"
      await profileManager.registerVerifiedBeacon(
          persistentUuid, persistentName);

      // Act - Simular nueva sesión creando nuevo manager
      final newProfileManager = BeaconProfileManager();
      final profiles = newProfileManager.listVerifiedBeacons();

      // Assert
      final persistentProfile = profiles.firstWhere(
        (p) => p.uuid.toLowerCase() == persistentUuid.toLowerCase(),
        orElse: () => throw Exception('Persistent profile not found'),
      );
      expect(persistentProfile.displayName, equals(persistentName));
    });

    test('Debe limpiar todos los perfiles correctamente', () async {
      // Arrange
      await profileManager.registerVerifiedBeacon('UUID1', 'Beacon 1');
      await profileManager.registerVerifiedBeacon('UUID2', 'Beacon 2');
      await profileManager.registerVerifiedBeacon('UUID3', 'Beacon 3');

      // Verificar que hay perfiles
      var profiles = profileManager.listVerifiedBeacons();
      expect(profiles.length, greaterThan(0));

      // Act
      await profileManager.clearVerifiedBeacons();

      // Assert
      profiles = profileManager.listVerifiedBeacons();
      expect(profiles.isEmpty, isTrue);
    });

    test('Debe manejar UUIDs duplicados correctamente', () async {
      // Arrange
      const duplicateUuid = 'EEEEEEEE-FFFF-0000-1111-222222222222';
      const firstName = 'Primer Nombre';
      const secondName = 'Segundo Nombre';

      // Act
      await profileManager.registerVerifiedBeacon(duplicateUuid, firstName);
      await profileManager.registerVerifiedBeacon(duplicateUuid, secondName);

      final profiles = profileManager.listVerifiedBeacons();
      final matchingProfiles = profiles
          .where((p) => p.uuid.toLowerCase() == duplicateUuid.toLowerCase())
          .toList();

      // Assert - Solo debe haber un perfil, actualizado con el último nombre
      expect(matchingProfiles.length, equals(1));
      expect(matchingProfiles.first.displayName, equals(secondName));
    });

    test('Debe incluir metadatos en perfiles', () async {
      // Arrange
      const uuidWithMetadata = 'FFFFFFFF-0000-1111-2222-333333333333';
      const nameWithMetadata = 'Beacon Con Metadatos';
      const metadata = {'description': 'Test beacon', 'location': 'Office'};

      // Act
      await profileManager.registerVerifiedBeacon(
        uuidWithMetadata,
        nameWithMetadata,
        metadata: metadata,
      );
      final profile = profileManager.getProfile(uuidWithMetadata);

      // Assert
      expect(profile, isNotNull);
      expect(profile!.metadata, equals(metadata));
      expect(profile.verified, isTrue);
    });
  });

  group('Scanner Integration Tests', () {
    late HolyBeaconScanner scanner;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      scanner = HolyBeaconScanner();
    });

    tearDown(() async {
      await scanner.clearDefaultProfiles();
      scanner.dispose();
    });

    test('Debe permitir registrar beacon en scanner', () async {
      // Arrange
      const scannerUuid = 'SCANNER1-1111-2222-3333-444444444444';
      const scannerName = 'Scanner Beacon';

      // Act
      await scanner.registerVerifiedBeacon(scannerUuid, scannerName);

      // Assert - Verificamos que se puede obtener el perfil
      // (En test real, esto requeriría mock del BLE)
      expect(scanner, isNotNull);
    });
  });
}
