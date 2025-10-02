import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Perfil de beacon configurable por el usuario
class BeaconProfile {
  final String uuid;
  final String displayName;
  final int trustLevel;
  final bool verified;
  final Map<String, dynamic>? metadata;

  const BeaconProfile({
    required this.uuid,
    required this.displayName,
    this.trustLevel = 5,
    this.verified = true,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'displayName': displayName,
        'trustLevel': trustLevel,
        'verified': verified,
        'metadata': metadata,
      };

  factory BeaconProfile.fromJson(Map<String, dynamic> json) => BeaconProfile(
        uuid: json['uuid'],
        displayName: json['displayName'],
        trustLevel: json['trustLevel'] ?? 5,
        verified: json['verified'] ?? true,
        metadata: json['metadata'],
      );

  @override
  String toString() =>
      'BeaconProfile(uuid: $uuid, name: $displayName, trust: $trustLevel)';
}

/// Gestión dinámica de perfiles de beacon con persistencia
class BeaconProfileManager {
  static const String _storageKey = 'holy_beacon_profiles';
  static const String _defaultsKey = 'holy_beacon_defaults_enabled';

  static final BeaconProfileManager _instance =
      BeaconProfileManager._internal();
  factory BeaconProfileManager() => _instance;
  BeaconProfileManager._internal();

  final Map<String, BeaconProfile> _profiles = {};
  bool _defaultsEnabled = true;

  /// Perfiles por defecto (Holly devices)
  static final List<BeaconProfile> _defaultProfiles = [
    const BeaconProfile(
      uuid: 'FDA50693-A4E2-4FB1-AFCF-C6EB07647825',
      displayName: 'Holy-Shun',
      trustLevel: 10,
      metadata: {'type': 'holy', 'category': 'shun'},
    ),
    const BeaconProfile(
      uuid: 'E2C56DB5-DFFB-48D2-B060-D0F5A7100000',
      displayName: 'Holy-IOT Jin',
      trustLevel: 10,
      metadata: {'type': 'holy', 'category': 'jin'},
    ),
    const BeaconProfile(
      uuid: 'F7826DA6-4FA2-4E98-8024-BC5B71E0893E',
      displayName: 'Kronos Blaze BLE',
      trustLevel: 9,
      metadata: {'type': 'kronos', 'category': 'blaze'},
    ),
  ];

  /// Inicializar desde almacenamiento local
  Future<void> initialize() async {
    await _loadFromStorage();
    if (_defaultsEnabled) {
      _addDefaultProfiles();
    }
  }

  /// Registrar un perfil de beacon verificado
  Future<void> registerVerifiedBeacon(
    String uuid,
    String name, {
    int trustLevel = 5,
    Map<String, dynamic>? metadata,
  }) async {
    final profile = BeaconProfile(
      uuid: uuid.toUpperCase(),
      displayName: name,
      trustLevel: trustLevel,
      verified: true,
      metadata: metadata,
    );

    _profiles[uuid.toUpperCase()] = profile;
    await _saveToStorage();
  }

  /// Desregistrar un perfil de beacon
  Future<void> unregisterVerifiedBeacon(String uuid) async {
    _profiles.remove(uuid.toUpperCase());
    await _saveToStorage();
  }

  /// Listar todos los perfiles registrados
  List<BeaconProfile> listVerifiedBeacons() {
    return _profiles.values.toList();
  }

  /// Limpiar todos los perfiles verificados (preservar o no defaults)
  Future<void> clearVerifiedBeacons({bool keepDefaults = false}) async {
    _profiles.clear();
    if (keepDefaults && _defaultsEnabled) {
      _addDefaultProfiles();
    }
    await _saveToStorage();
  }

  /// Limpiar/deshabilitar perfiles por defecto
  Future<void> clearDefaultProfiles() async {
    _defaultsEnabled = false;
    // Remover perfiles por defecto actuales
    for (final defaultProfile in _defaultProfiles) {
      _profiles.remove(defaultProfile.uuid.toUpperCase());
    }
    await _saveToStorage();
    await _saveDefaultsState();
  }

  /// Restaurar perfiles por defecto
  Future<void> restoreDefaultProfiles() async {
    _defaultsEnabled = true;
    _addDefaultProfiles();
    await _saveToStorage();
    await _saveDefaultsState();
  }

  /// Obtener perfil por UUID
  BeaconProfile? getProfile(String uuid) {
    return _profiles[uuid.toUpperCase()];
  }

  /// Verificar si un UUID está registrado como verificado
  bool isVerifiedBeacon(String uuid) {
    final profile = _profiles[uuid.toUpperCase()];
    return profile?.verified ?? false;
  }

  /// Obtener todos los UUIDs conocidos
  List<String> getKnownUuids() {
    return _profiles.keys.toList();
  }

  /// Verificar si los defaults están habilitados
  bool get defaultsEnabled => _defaultsEnabled;

  /// Estadísticas de perfiles
  Map<String, int> getStats() {
    final total = _profiles.length;
    final defaults = _profiles.values
        .where((p) => _defaultProfiles.any((d) => d.uuid == p.uuid))
        .length;
    final custom = total - defaults;

    return {
      'total': total,
      'defaults': defaults,
      'custom': custom,
      'verified': _profiles.values.where((p) => p.verified).length,
    };
  }

  // Métodos privados para persistencia

  void _addDefaultProfiles() {
    for (final profile in _defaultProfiles) {
      _profiles[profile.uuid.toUpperCase()] = profile;
    }
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar perfiles
      final profilesJson = prefs.getString(_storageKey);
      if (profilesJson != null) {
        final Map<String, dynamic> data = json.decode(profilesJson);
        _profiles.clear();
        data.forEach((uuid, profileData) {
          _profiles[uuid] = BeaconProfile.fromJson(profileData);
        });
      }

      // Cargar estado de defaults
      _defaultsEnabled = prefs.getBool(_defaultsKey) ?? true;
    } catch (e) {
      print('Error loading beacon profiles: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> data = {};

      _profiles.forEach((uuid, profile) {
        data[uuid] = profile.toJson();
      });

      await prefs.setString(_storageKey, json.encode(data));
    } catch (e) {
      print('Error saving beacon profiles: $e');
    }
  }

  Future<void> _saveDefaultsState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_defaultsKey, _defaultsEnabled);
    } catch (e) {
      print('Error saving defaults state: $e');
    }
  }
}
