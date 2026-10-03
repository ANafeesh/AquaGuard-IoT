import '../constants/parameter_thresholds.dart';
import 'water_source.dart';

enum ParameterType {
  ph,
  tds,
  turbidity,
  temperature,
}

class ParameterReading {
  final ParameterType type;
  final String name;
  final String shortName;
  final double value;
  final String unit;
  final WaterQualityStatus status;
  final String statusText;
  final double normalMin;
  final double normalMax;

  const ParameterReading({
    required this.type,
    required this.name,
    required this.shortName,
    required this.value,
    required this.unit,
    required this.status,
    required this.statusText,
    required this.normalMin,
    required this.normalMax,
  });

  /// Factory helper that automatically initializes reference thresholds
  factory ParameterReading.fromType({
    required ParameterType type,
    required double value,
    WaterQualityStatus? status,
  }) {
    switch (type) {
      case ParameterType.ph:
        final isTypical = ParameterThresholds.isPhTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.phLabel,
          shortName: ParameterThresholds.phShortLabel,
          value: value,
          unit: ParameterThresholds.phUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.phMin,
          normalMax: ParameterThresholds.phMax,
        );
      case ParameterType.tds:
        final isTypical = ParameterThresholds.isTdsTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.tdsLabel,
          shortName: ParameterThresholds.tdsShortLabel,
          value: value,
          unit: ParameterThresholds.tdsUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.tdsMin,
          normalMax: ParameterThresholds.tdsMax,
        );
      case ParameterType.turbidity:
        final isTypical = ParameterThresholds.isTurbidityTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.turbidityLabel,
          shortName: ParameterThresholds.turbidityShortLabel,
          value: value,
          unit: ParameterThresholds.turbidityUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.turbidityMin,
          normalMax: ParameterThresholds.turbidityMax,
        );
      case ParameterType.temperature:
        final isTypical = ParameterThresholds.isTempTypical(value);
        return ParameterReading(
          type: type,
          name: ParameterThresholds.tempLabel,
          shortName: ParameterThresholds.tempShortLabel,
          value: value,
          unit: ParameterThresholds.tempUnit,
          status: status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual),
          statusText: (status ?? (isTypical ? WaterQualityStatus.withinTypicalRange : WaterQualityStatus.unusual)).label,
          normalMin: ParameterThresholds.tempMin,
          normalMax: ParameterThresholds.tempMax,
        );
    }
  }
}

class HistoricalPoint {
  final String timeLabel;
  final double value;

  const HistoricalPoint(this.timeLabel, this.value);
}
