import '../config/parameter_thresholds.dart';

/// Result of validating a water quality reading input
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  factory ValidationResult.success() => const ValidationResult(isValid: true);

  factory ValidationResult.failure(String message, [Map<String, String> errors = const {}]) =>
      ValidationResult(isValid: false, errorMessage: message, fieldErrors: errors);
}

/// Validates reading parameters according to specified physical and instrument bounds:
/// - pH: 0.0 – 14.0
/// - Temperature: -5.0 to 60.0 °C
/// - Turbidity: ≥ 0.0 NTU
/// - TDS/EC: ≥ 0.0 ppm
/// - Each parameter is optional, but at least ONE parameter must be provided.
class ReadingValidator {
  static ValidationResult validateForm({
    String? sourceId,
    String? newSourceName,
    bool isNewSource = false,
    double? ph,
    double? temperature,
    double? turbidity,
    double? tdsEc,
  }) {
    final Map<String, String> errors = {};

    // Source validation
    if (isNewSource) {
      if (newSourceName == null || newSourceName.trim().isEmpty) {
        errors['sourceName'] = 'Water source name is required for new source';
      }
    } else {
      if (sourceId == null || sourceId.trim().isEmpty) {
        errors['sourceId'] = 'Please select a monitored water source';
      }
    }

    // At least one parameter must be present
    final hasAtLeastOne = ph != null || temperature != null || turbidity != null || tdsEc != null;
    if (!hasAtLeastOne) {
      return ValidationResult.failure(
        'At least one water-quality parameter (pH, TDS/EC, Turbidity, or Temperature) must be entered.',
        {'parameters': 'At least one parameter is required'},
      );
    }

    // pH validation: 0.0 – 14.0
    if (ph != null) {
      if (ph < ParameterThresholds.inputPhMin || ph > ParameterThresholds.inputPhMax) {
        errors['ph'] = 'pH must be between 0.0 and 14.0';
      }
    }

    // Temperature validation: -5.0 to 60.0 °C
    if (temperature != null) {
      if (temperature < ParameterThresholds.inputTempMin || temperature > ParameterThresholds.inputTempMax) {
        errors['temperature'] = 'Temperature must be between -5.0°C and 60.0°C';
      }
    }

    // Turbidity validation: ≥ 0.0 NTU
    if (turbidity != null) {
      if (turbidity < ParameterThresholds.inputTurbidityMin) {
        errors['turbidity'] = 'Turbidity cannot be negative';
      }
    }

    // TDS/EC validation: ≥ 0.0 ppm
    if (tdsEc != null) {
      if (tdsEc < ParameterThresholds.inputTdsMin) {
        errors['tdsEc'] = 'TDS/EC cannot be negative';
      }
    }

    if (errors.isNotEmpty) {
      final firstMsg = errors.values.first;
      return ValidationResult.failure(firstMsg, errors);
    }

    return ValidationResult.success();
  }

  /// Individual field validators for Flutter FormFields
  static String? validatePhField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < ParameterThresholds.inputPhMin || val > ParameterThresholds.inputPhMax) {
      return 'pH must be between 0.0 and 14.0';
    }
    return null;
  }

  static String? validateTempField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < ParameterThresholds.inputTempMin || val > ParameterThresholds.inputTempMax) {
      return 'Temp must be between -5.0°C and 60.0°C';
    }
    return null;
  }

  static String? validateTurbidityField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < ParameterThresholds.inputTurbidityMin) {
      return 'Turbidity cannot be negative';
    }
    return null;
  }

  static String? validateTdsField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final val = double.tryParse(value);
    if (val == null) return 'Enter a valid number';
    if (val < ParameterThresholds.inputTdsMin) {
      return 'TDS cannot be negative';
    }
    return null;
  }
}
