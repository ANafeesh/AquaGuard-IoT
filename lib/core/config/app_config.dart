/// Global application configuration and environment settings.
class AppConfig {
  static const String appName = 'AquaGuard';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  /// Whether to force in-memory/mock repository implementations
  static bool useMockData = false;

  /// Whether Firebase was successfully initialized at startup
  static bool isFirebaseInitialized = false;

  /// CARTO Basemaps API key to remove watermark from map tiles.
  /// Free registration at: https://carto.com/basemaps/apikey/
  static const String cartoApiKey = 'cb1_4kmk_1_1b7de93d697ccefbed78fb0e';

  /// Generates the map tile URL with optional CARTO API key
  static String getMapTileUrl({required bool isDark}) {
    final base = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
        : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
    return cartoApiKey.isNotEmpty ? '$base?key=$cartoApiKey' : base;
  }

  /// Regulatory limitations and project purpose statement
  static const String limitationsStatement =
      'AquaGuard monitors selected water-quality indicators (pH, TDS/EC, turbidity, '
      'and water temperature) using an ESP32 hardware node and community observations. '
      'AquaGuard DOES NOT certify whether water is safe to drink, potable, or free of biological pathogens. '
      'All classifications (e.g., "within expected range" or "unusual change detected") represent environmental '
      'sensor baseline comparisons only. Always consult authorized public health authorities and certified '
      'laboratory testing before consuming water from unverified sources.';

  /// Firestore base collection names
  static const String sourcesCollection = 'sources';
  static const String measurementsCollection = 'measurements';
  static const String devicesCollection = 'devices';
  static const String alertsCollection = 'alerts';
  static const String observationsCollection = 'observations';

  /// Demo collection prefix for separating test demo data from production
  static const String demoPrefix = 'demo_';

  /// Helpers to resolve collection name based on demo mode
  static String getSourcesCollection({bool isDemo = false}) =>
      isDemo ? '$demoPrefix$sourcesCollection' : sourcesCollection;

  static String getMeasurementsCollection({bool isDemo = false}) =>
      isDemo ? '$demoPrefix$measurementsCollection' : measurementsCollection;

  static String getDevicesCollection({bool isDemo = false}) =>
      isDemo ? '$demoPrefix$devicesCollection' : devicesCollection;

  static String getAlertsCollection({bool isDemo = false}) =>
      isDemo ? '$demoPrefix$alertsCollection' : alertsCollection;

  static String getObservationsCollection({bool isDemo = false}) =>
      isDemo ? '$demoPrefix$observationsCollection' : observationsCollection;
}
