/// Centralized reference thresholds for AquaGuard water quality indicators.
/// Strictly uses environmental indicator baselines (never potable safety claims).
class ParameterThresholds {
  // pH Level
  static const double phMin = 6.5;
  static const double phMax = 8.5;
  static const String phUnit = '';
  static const String phLabel = 'pH Level';
  static const String phShortLabel = 'pH';

  // TDS / Electrical Conductivity (ppm)
  static const double tdsMin = 150.0;
  static const double tdsMax = 500.0;
  static const String tdsUnit = 'ppm';
  static const String tdsLabel = 'TDS / EC';
  static const String tdsShortLabel = 'TDS / EC';

  // Turbidity (NTU)
  static const double turbidityMin = 0.5;
  static const double turbidityMax = 5.0;
  static const String turbidityUnit = 'NTU';
  static const String turbidityLabel = 'Turbidity';
  static const String turbidityShortLabel = 'Turbidity';

  // Temperature (°C)
  static const double tempMin = 20.0;
  static const double tempMax = 32.0;
  static const String tempUnit = '°C';
  static const String tempLabel = 'Water Temperature';
  static const String tempShortLabel = 'Temp';

  /// Helper to check if a pH reading is within typical baseline
  static bool isPhTypical(double value) => value >= phMin && value <= phMax;

  /// Helper to check if a TDS reading is within typical baseline
  static bool isTdsTypical(double value) => value >= tdsMin && value <= tdsMax;

  /// Helper to check if a Turbidity reading is within typical baseline
  static bool isTurbidityTypical(double value) => value >= turbidityMin && value <= turbidityMax;

  /// Helper to check if a Temperature reading is within typical baseline
  static bool isTempTypical(double value) => value >= tempMin && value <= tempMax;
}
