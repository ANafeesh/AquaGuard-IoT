/// Global application configuration and environment settings.
class AppConfig {
  static const String appName = 'AquaGuard';
  static const String appVersion = '1.0.0';
  static const String appBuild = '1';

  /// Whether to force in-memory/mock repository implementations
  static bool useMockData = false;

  /// Whether Firebase was successfully initialized at application startup
  static bool isFirebaseInitialized = false;

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
}
