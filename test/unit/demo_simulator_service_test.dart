import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/core/services/demo_simulator_service.dart';
import 'package:aquaguard/models/water_source.dart';

void main() {
  group('DemoSimulatorService Tests', () {
    test('getDemoSources returns 3 distinct realistic water sources', () {
      final sources = DemoSimulatorService.getDemoSources();
      expect(sources.length, 3);

      final types = sources.map((s) => s.type).toList();
      expect(types.contains(WaterSourceType.river), isTrue);
      expect(types.contains(WaterSourceType.well), isTrue);
      expect(types.contains(WaterSourceType.reservoir), isTrue);

      // Verify that Blue River has the turbidity anomaly status flagged
      final river = sources.firstWhere((s) => s.id == 'demo_src_river');
      expect(river.status, WaterQualityStatus.unusual);
      expect(river.turbidity, 18.5);
    });

    test('getDemoMeasurements generates 7 days of realistic readings', () {
      final measurements = DemoSimulatorService.getDemoMeasurements();
      expect(measurements.isNotEmpty, isTrue);

      // 8 days (day 7 to day 0) * 4 samples per day * 3 sources = ~96 samples
      expect(measurements.length, greaterThanOrEqualTo(72));

      // Check all 4 indicators exist and are within bounds
      for (final m in measurements) {
        expect(m.ph, inInclusiveRange(5.0, 9.5));
        expect(m.tdsEc, greaterThan(0.0));
        expect(m.turbidity, greaterThan(0.0));
        expect(m.temperature, inInclusiveRange(20.0, 35.0));
      }

      // Check that the turbidity anomaly on the river exists
      final anomalies = measurements.where((m) => m.sourceId == 'demo_src_river' && m.turbidity >= 15.0);
      expect(anomalies.isNotEmpty, isTrue);
    });

    test('getDemoAlerts returns designated anomaly alert with investigation advice', () {
      final alerts = DemoSimulatorService.getDemoAlerts();
      expect(alerts.length, 1);

      final alert = alerts.first;
      expect(alert.parameter, 'Turbidity');
      expect(alert.value, 18.5);
      expect(alert.severity, WaterQualityStatus.unusual);
      expect(alert.waterSourceName, 'Blue River Reach');
      expect(alert.investigationAdvice, contains('Field inspection recommended'));
    });

    test('getDemoDevices returns 3 hardware nodes with battery and status', () {
      final devices = DemoSimulatorService.getDemoDevices();
      expect(devices.length, 3);

      final onlineDevices = devices.where((d) => d.isOnline).toList();
      final offlineDevices = devices.where((d) => !d.isOnline).toList();

      expect(onlineDevices.length, 2);
      expect(offlineDevices.length, 1);
    });
  });
}
