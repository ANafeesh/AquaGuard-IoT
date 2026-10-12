import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';
import '../core/services/demo_simulator_service.dart';

class UserPreferences {
  final bool isOfflineSimulated;
  final bool offlineDataSync;
  final bool sensorAutoRefresh;
  final bool gpsLocationAccess;
  final bool pushNotifications;
  final String temperatureUnit; // '°C' or '°F'
  final String tdsUnit;         // 'ppm' or 'µS/cm'
  final String turbidityUnit;   // 'NTU' or 'JTU'
  final String mapStyle;
  final bool isDemoMode;
  final bool isDarkMode;

  const UserPreferences({
    this.isOfflineSimulated = false,
    this.offlineDataSync = true,
    this.sensorAutoRefresh = true,
    this.gpsLocationAccess = true,
    this.pushNotifications = true,
    this.temperatureUnit = '°C',
    this.tdsUnit = 'ppm',
    this.turbidityUnit = 'NTU',
    this.mapStyle = 'Environmental Terrain',
    this.isDemoMode = false,
    this.isDarkMode = false,
  });

  bool get useFahrenheit => temperatureUnit == '°F';
  bool get useMicroSiemens => tdsUnit == 'µS/cm';
  bool get useJtu => turbidityUnit == 'JTU';

  UserPreferences copyWith({
    bool? isOfflineSimulated,
    bool? offlineDataSync,
    bool? sensorAutoRefresh,
    bool? gpsLocationAccess,
    bool? pushNotifications,
    String? temperatureUnit,
    String? tdsUnit,
    String? turbidityUnit,
    String? mapStyle,
    bool? isDemoMode,
    bool? isDarkMode,
  }) {
    return UserPreferences(
      isOfflineSimulated: isOfflineSimulated ?? this.isOfflineSimulated,
      offlineDataSync: offlineDataSync ?? this.offlineDataSync,
      sensorAutoRefresh: sensorAutoRefresh ?? this.sensorAutoRefresh,
      gpsLocationAccess: gpsLocationAccess ?? this.gpsLocationAccess,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      tdsUnit: tdsUnit ?? this.tdsUnit,
      turbidityUnit: turbidityUnit ?? this.turbidityUnit,
      mapStyle: mapStyle ?? this.mapStyle,
      isDemoMode: isDemoMode ?? this.isDemoMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
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
      final isDemo = map['isDemoMode'] ?? false;
      if (isDemo) {
        DemoSimulatorService.instance.startDemoMode(onNewLiveReading: (_) {});
      }
      return UserPreferences(
        isOfflineSimulated: map['isOfflineSimulated'] ?? false,
        offlineDataSync: map['offlineDataSync'] ?? true,
        sensorAutoRefresh: map['sensorAutoRefresh'] ?? true,
        gpsLocationAccess: map['gpsLocationAccess'] ?? true,
        pushNotifications: map['pushNotifications'] ?? true,
        temperatureUnit: map['temperatureUnit'] ?? '°C',
        tdsUnit: map['tdsUnit'] ?? 'ppm',
        turbidityUnit: map['turbidityUnit'] ?? 'NTU',
        mapStyle: map['mapStyle'] ?? 'Environmental Terrain',
        isDemoMode: isDemo,
        isDarkMode: map['isDarkMode'] ?? false,
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
      'tdsUnit': newPrefs.tdsUnit,
      'turbidityUnit': newPrefs.turbidityUnit,
      'mapStyle': newPrefs.mapStyle,
      'isDemoMode': newPrefs.isDemoMode,
      'isDarkMode': newPrefs.isDarkMode,
    });
  }

  Future<void> toggleDemoMode() async {
    final newDemo = !state.isDemoMode;
    if (newDemo) {
      DemoSimulatorService.instance.startDemoMode(onNewLiveReading: (_) {});
    } else {
      DemoSimulatorService.instance.stopDemoMode();
    }
    final updated = state.copyWith(isDemoMode: newDemo);
    await updatePreferences(updated);
  }

  Future<void> toggleDarkMode() async {
    final updated = state.copyWith(isDarkMode: !state.isDarkMode);
    await updatePreferences(updated);
  }

  Future<void> toggleOfflineSimulation() async {
    final updated = state.copyWith(isOfflineSimulated: !state.isOfflineSimulated);
    await updatePreferences(updated);
  }

  Future<void> setTemperatureUnit(String unit) async {
    final updated = state.copyWith(temperatureUnit: unit);
    await updatePreferences(updated);
  }

  Future<void> setTdsUnit(String unit) async {
    final updated = state.copyWith(tdsUnit: unit);
    await updatePreferences(updated);
  }

  Future<void> setTurbidityUnit(String unit) async {
    final updated = state.copyWith(turbidityUnit: unit);
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
