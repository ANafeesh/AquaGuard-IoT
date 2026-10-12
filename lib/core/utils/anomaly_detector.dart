import 'dart:math';
import '../config/parameter_thresholds.dart';

/// Encapsulates the evaluation result of an anomaly detection check
class AnomalyEvaluation {
  final bool isAnomaly;
  final String parameter;
  final double currentValue;
  final double? previousValue;
  final double? mean;
  final double? stdDev;
  final double? zScore;
  final double? delta;
  final String message;
  final String explanation;

  const AnomalyEvaluation({
    required this.isAnomaly,
    required this.parameter,
    required this.currentValue,
    this.previousValue,
    this.mean,
    this.stdDev,
    this.zScore,
    this.delta,
    this.message = 'Unusual water-quality measurement detected at this location.',
    required this.explanation,
  });

  factory AnomalyEvaluation.normal({
    required String parameter,
    required double currentValue,
  }) {
    return AnomalyEvaluation(
      isAnomaly: false,
      parameter: parameter,
      currentValue: currentValue,
      explanation: 'Measurement is within baseline expectations.',
    );
  }
}

/// Client-side explainable anomaly detection engine for AquaGuard.
/// Evaluates readings using:
/// 1) Statistical Z-score (more than 3 standard deviations from the last 30 readings mean)
/// 2) Fixed delta jump from the immediate previous reading (demonstration thresholds)
/// 
/// Note: Never labels water as "unsafe", "clean", or "potable"; all evaluations
/// report neutral indicator shifts (e.g., "unusual change detected").
class AnomalyDetector {
  /// Evaluates a specific parameter series for anomaly condition.
  /// [currentValue]: The newest reading value
  /// [previousReadings]: Up to the last 30 readings (ordered chronologically or reverse, we handle list)
  /// [parameter]: Parameter name ('ph', 'temperature', 'turbidity', 'tdsEc')
  static AnomalyEvaluation evaluateParameter({
    required String parameter,
    required double currentValue,
    required List<double> previousReadings,
  }) {
    // 1. Check fixed delta threshold against the most immediate previous reading
    if (previousReadings.isNotEmpty) {
      final prevVal = previousReadings.last;
      final delta = (currentValue - prevVal).abs();

      final fixedThreshold = _getFixedThresholdFor(parameter);
      if (fixedThreshold != null && delta > fixedThreshold) {
        return AnomalyEvaluation(
          isAnomaly: true,
          parameter: parameter,
          currentValue: currentValue,
          previousValue: prevVal,
          delta: delta,
          message: 'Unusual water-quality measurement detected at this location.',
          explanation:
              'Rapid single-step change of ${delta.toStringAsFixed(2)} detected '
              '(configured test threshold: > ${fixedThreshold.toStringAsFixed(1)}).',
        );
      }
    }

    // 2. Statistical Z-Score comparison against mean & stdDev (up to last 30 readings)
    // Only calculate when at least 5 baseline points exist to prevent premature variance distortion
    final window = previousReadings.length > 30
        ? previousReadings.sublist(previousReadings.length - 30)
        : previousReadings;

    if (window.length >= 5) {
      final mean = window.reduce((a, b) => a + b) / window.length;
      final variance =
          window.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / window.length;
      final stdDev = sqrt(variance);

      // Avoid division by zero if all prior values were identical
      if (stdDev > 0.001) {
        final zScore = ((currentValue - mean) / stdDev).abs();
        if (zScore > 3.0) {
          return AnomalyEvaluation(
            isAnomaly: true,
            parameter: parameter,
            currentValue: currentValue,
            previousValue: window.last,
            mean: mean,
            stdDev: stdDev,
            zScore: zScore,
            message: 'Unusual water-quality measurement detected at this location.',
            explanation:
                'Value deviates ${zScore.toStringAsFixed(1)} standard deviations '
                'from the 30-reading baseline mean of ${mean.toStringAsFixed(2)}.',
          );
        }
      }
    }

    return AnomalyEvaluation.normal(
      parameter: parameter,
      currentValue: currentValue,
    );
  }

  /// Evaluates all 4 parameters of a reading against historical series
  static List<AnomalyEvaluation> evaluateAll({
    required double ph,
    required double temperature,
    required double turbidity,
    required double tdsEc,
    required List<double> historicalPh,
    required List<double> historicalTemp,
    required List<double> historicalTurbidity,
    required List<double> historicalTds,
  }) {
    final List<AnomalyEvaluation> results = [];

    final phEval = evaluateParameter(
      parameter: 'pH',
      currentValue: ph,
      previousReadings: historicalPh,
    );
    if (phEval.isAnomaly) results.add(phEval);

    final tempEval = evaluateParameter(
      parameter: 'Temperature',
      currentValue: temperature,
      previousReadings: historicalTemp,
    );
    if (tempEval.isAnomaly) results.add(tempEval);

    final turbEval = evaluateParameter(
      parameter: 'Turbidity',
      currentValue: turbidity,
      previousReadings: historicalTurbidity,
    );
    if (turbEval.isAnomaly) results.add(turbEval);

    final tdsEval = evaluateParameter(
      parameter: 'TDS/EC',
      currentValue: tdsEc,
      previousReadings: historicalTds,
    );
    if (tdsEval.isAnomaly) results.add(tdsEval);

    return results;
  }

  static double? _getFixedThresholdFor(String parameter) {
    final paramLower = parameter.toLowerCase();
    if (paramLower.contains('ph')) {
      return ParameterThresholds.anomalyDeltaPh;
    }
    if (paramLower.contains('temp')) {
      return ParameterThresholds.anomalyDeltaTemp;
    }
    if (paramLower.contains('turbid')) {
      return ParameterThresholds.anomalyDeltaTurbidity;
    }
    if (paramLower.contains('tds') || paramLower.contains('ec')) {
      return ParameterThresholds.anomalyDeltaTds;
    }
    return null;
  }
}
