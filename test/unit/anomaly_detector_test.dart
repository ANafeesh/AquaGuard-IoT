import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/core/utils/anomaly_detector.dart';

void main() {
  group('AnomalyDetector - Fixed Delta Jump Thresholds', () {
    test('pH jump greater than 1.5 triggers anomaly', () {
      final prevReadings = [7.0, 7.1, 7.0];
      final currentPh = 8.6; // Delta = 1.6 > 1.5

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'pH',
        currentValue: currentPh,
        previousReadings: prevReadings,
      );

      expect(result.isAnomaly, isTrue);
      expect(result.parameter, 'pH');
      expect(result.delta, closeTo(1.6, 0.01));
      expect(result.message, 'Unusual water-quality measurement detected at this location.');
      expect(result.explanation.contains('Rapid single-step change'), isTrue);
    });

    test('pH jump within 1.5 delta remains normal', () {
      final prevReadings = [7.0, 7.1, 7.2];
      final currentPh = 7.8; // Delta = 0.6 <= 1.5

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'pH',
        currentValue: currentPh,
        previousReadings: prevReadings,
      );

      expect(result.isAnomaly, isFalse);
    });

    test('Temperature jump greater than 5.0 °C triggers anomaly', () {
      final prevReadings = [24.0, 24.5, 25.0];
      final currentTemp = 30.5; // Delta = 5.5 > 5.0

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'Temperature',
        currentValue: currentTemp,
        previousReadings: prevReadings,
      );

      expect(result.isAnomaly, isTrue);
      expect(result.parameter, 'Temperature');
      expect(result.message, 'Unusual water-quality measurement detected at this location.');
      expect(result.delta, closeTo(5.5, 0.01));
    });

    test('Turbidity jump greater than 15.0 NTU triggers anomaly', () {
      final prevReadings = [2.0, 2.5, 3.0];
      final currentTurbidity = 18.5; // Delta = 15.5 > 15.0

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'Turbidity',
        currentValue: currentTurbidity,
        previousReadings: prevReadings,
      );

      expect(result.isAnomaly, isTrue);
      expect(result.parameter, 'Turbidity');
      expect(result.delta, closeTo(15.5, 0.01));
    });

    test('TDS jump greater than 150.0 ppm triggers anomaly', () {
      final prevReadings = [250.0, 260.0, 270.0];
      final currentTds = 430.0; // Delta = 160.0 > 150.0

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'TDS/EC',
        currentValue: currentTds,
        previousReadings: prevReadings,
      );

      expect(result.isAnomaly, isTrue);
      expect(result.parameter, 'TDS/EC');
      expect(result.delta, closeTo(160.0, 0.01));
    });
  });

  group('AnomalyDetector - 3 Standard Deviations (Z-Score)', () {
    test('Reading deviating more than 3 standard deviations from last 30 mean triggers anomaly', () {
      // 30 readings stable at 7.00 with slight variance (stdDev ≈ 0.05)
      final List<double> history30 = List.generate(
        30,
        (i) => 7.0 + ((i % 5) - 2) * 0.02, // values: 6.96, 6.98, 7.00, 7.02, 7.04
      );

      // Mean is 7.00, stdDev is ~0.028.
      // A small delta of 0.25 is below the fixed threshold (1.5),
      // but is ~8.9 standard deviations away from the 30-reading mean!
      final currentValue = 7.25;

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'pH',
        currentValue: currentValue,
        previousReadings: history30,
      );

      expect(result.isAnomaly, isTrue);
      expect(result.zScore, isNotNull);
      expect(result.zScore!, greaterThan(3.0));
      expect(result.explanation.contains('standard deviations from the 30-reading baseline'), isTrue);
    });

    test('Reading within 3 standard deviations remains normal', () {
      final List<double> history30 = List.generate(
        30,
        (i) => 25.0 + ((i % 7) - 3) * 0.5,
      );

      final currentValue = 25.2;

      final result = AnomalyDetector.evaluateParameter(
        parameter: 'Temperature',
        currentValue: currentValue,
        previousReadings: history30,
      );

      expect(result.isAnomaly, isFalse);
    });
  });

  group('AnomalyDetector - Terminology and Multi-parameter Evaluation', () {
    test('Strict adherence to non-potable and neutral messaging', () {
      final prevReadings = [3.0, 3.1, 3.2];
      final result = AnomalyDetector.evaluateParameter(
        parameter: 'Turbidity',
        currentValue: 20.0,
        previousReadings: prevReadings,
      );

      final combined = '${result.message} ${result.explanation}'.toLowerCase();
      expect(combined.contains('safe'), isFalse);
      expect(combined.contains('clean'), isFalse);
      expect(combined.contains('potable'), isFalse);
      expect(combined.contains('drink'), isFalse);
    });

    test('evaluateAll evaluates all 4 indicators and flags multiple anomalies', () {
      final historyPh = [7.0, 7.1, 7.0];
      final historyTurbidity = [2.0, 2.5, 3.0]; // delta to 20.0 is 17.0 > 15.0 NTU threshold

      final results = AnomalyDetector.evaluateAll(
        ph: 9.0, // Delta 2.0 > 1.5 -> Anomaly
        temperature: 25.0, // Normal
        turbidity: 20.0, // Delta 17.0 > 15.0 -> Anomaly
        tdsEc: 260.0, // Normal
        historicalPh: historyPh,
        historicalTemp: [25.0, 25.0, 25.0],
        historicalTurbidity: historyTurbidity,
        historicalTds: [250.0, 255.0, 260.0],
      );

      expect(results.length, 2);
      expect(results.any((r) => r.parameter == 'pH'), isTrue);
      expect(results.any((r) => r.parameter == 'Turbidity'), isTrue);
      expect(results.any((r) => r.parameter == 'Temperature'), isFalse);
      expect(results.any((r) => r.parameter == 'TDS/EC'), isFalse);
    });
  });
}
