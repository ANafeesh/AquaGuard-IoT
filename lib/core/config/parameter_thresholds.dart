/// Centralized reference thresholds for AquaGuard water quality indicators.
/// 
/// NOTE: The thresholds below are DEMONSTRATION VALUES configured for IoT testing
/// and anomaly simulation. They are NOT scientific standards, medical baselines,
/// or potable drinking water safety criteria. AquaGuard monitors selected indicators
/// only and does not certify whether water is safe to drink.
class ParameterThresholds {
  // Demonstration baseline limits for typical environmental surface/well water
  // pH Level (unitless)
  static const double phMin = 6.5;
  static const double phMax = 8.5;
  static const String phUnit = '';
  static const String phLabel = 'pH Level';
  static const String phShortLabel = 'pH';

  // Total Dissolved Solids / Electrical Conductivity (ppm or µS/cm)
  static const double tdsMin = 150.0;
  static const double tdsMax = 500.0;
  static const String tdsUnit = 'ppm';
  static const String tdsLabel = 'TDS / EC';
  static const String tdsShortLabel = 'TDS';

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

  // --- FIXED ANOMALY DELTA THRESHOLDS (Demonstration values) ---
  // A sudden single-step difference greater than these triggers an anomaly alert.
  static const double anomalyDeltaPh = 1.5;
  static const double anomalyDeltaTemp = 5.0; // °C
  static const double anomalyDeltaTurbidity = 15.0; // NTU
  static const double anomalyDeltaTds = 150.0; // ppm

  // Valid input range limits for manual community reports
  static const double inputPhMin = 0.0;
  static const double inputPhMax = 14.0;
  static const double inputTempMin = -5.0;
  static const double inputTempMax = 60.0;
  static const double inputTurbidityMin = 0.0;
  static const double inputTdsMin = 0.0;

  /// Check if a pH reading is within demonstration baseline
  static bool isPhTypical(double value) => value >= phMin && value <= phMax;

  /// Check if a TDS reading is within demonstration baseline
  static bool isTdsTypical(double value) => value >= tdsMin && value <= tdsMax;

  /// Check if Turbidity is within demonstration baseline
  static bool isTurbidityTypical(double value) => value >= turbidityMin && value <= turbidityMax;

  /// Check if Temperature is within demonstration baseline
  static bool isTempTypical(double value) => value >= tempMin && value <= tempMax;
}
