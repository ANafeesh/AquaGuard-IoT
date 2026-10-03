import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

class UserPreferences {
  final bool isOfflineSimulated;
  final bool offlineDataSync;
  final bool sensorAutoRefresh;
  final bool gpsLocationAccess;
  final bool pushNotifications;
  final String temperatureUnit; // '°C' or '°F'
  final String mapStyle;

  const UserPreferences({
    this.isOfflineSimulated = false,
    this.offlineDataSync = true,
    this.sensorAutoRefresh = true,
    this.gpsLocationAccess = true,
    this.pushNotifications = true,
    this.temperatureUnit = '°C',
    this.mapStyle = 'Environmental Terrain',
  });

  UserPreferences copyWith({
    bool? isOfflineSimulated,
    bool? offlineDataSync,
    bool? sensorAutoRefresh,
    bool? gpsLocationAccess,
    bool? pushNotifications,
    String? temperatureUnit,
    String? mapStyle,
  }) {
    return UserPreferences(
      isOfflineSimulated: isOfflineSimulated ?? this.isOfflineSimulated,
      offlineDataSync: offlineDataSync ?? this.offlineDataSync,
      sensorAutoRefresh: sensorAutoRefresh ?? this.sensorAutoRefresh,
      gpsLocationAccess: gpsLocationAccess ?? this.gpsLocationAccess,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      mapStyle: mapStyle ?? this.mapStyle,
    );
  }
}

class UserPreferencesNotifier extends Notifier<UserPreferences> {
  static const String _storageKey = 'user_preferences';

  @override
  UserPreferences build() {
    final storage = LocalStorageService.instance;
    final map = storage.getMap(_storageKey);
    if (map != null) {
      return UserPreferences(
        isOfflineSimulated: map['isOfflineSimulated'] ?? false,
        offlineDataSync: map['offlineDataSync'] ?? true,
        sensorAutoRefresh: map['sensorAutoRefresh'] ?? true,
        gpsLocationAccess: map['gpsLocationAccess'] ?? true,
        pushNotifications: map['pushNotifications'] ?? true,
        temperatureUnit: map['temperatureUnit'] ?? '°C',
        mapStyle: map['mapStyle'] ?? 'Environmental Terrain',
      );
    }
    return const UserPreferences();
  }

  Future<void> updatePreferences(UserPreferences newPrefs) async {
    state = newPrefs;
    await LocalStorageService.instance.setMap(_storageKey, {
      'isOfflineSimulated': newPrefs.isOfflineSimulated,
      'offlineDataSync': newPrefs.offlineDataSync,
      'sensorAutoRefresh': newPrefs.sensorAutoRefresh,
      'gpsLocationAccess': newPrefs.gpsLocationAccess,
      'pushNotifications': newPrefs.pushNotifications,
      'temperatureUnit': newPrefs.temperatureUnit,
      'mapStyle': newPrefs.mapStyle,
    });
  }

  Future<void> toggleOfflineSimulation() async {
    final updated = state.copyWith(isOfflineSimulated: !state.isOfflineSimulated);
    await updatePreferences(updated);
  }

  Future<void> setTemperatureUnit(String unit) async {
    final updated = state.copyWith(temperatureUnit: unit);
    await updatePreferences(updated);
  }

  Future<void> setMapStyle(String style) async {
    final updated = state.copyWith(mapStyle: style);
    await updatePreferences(updated);
  }
}

final userPreferencesProvider =
    NotifierProvider<UserPreferencesNotifier, UserPreferences>(UserPreferencesNotifier.new);

/// Helper for temperature conversion across screens
extension TemperatureConverter on double {
  String formatTemperature(String unit) {
    if (unit == '°F') {
      final fahrenheit = (this * 9 / 5) + 32;
      return '${fahrenheit.toStringAsFixed(1)}°F';
    }
    return '${toStringAsFixed(1)}°C';
  }
}
