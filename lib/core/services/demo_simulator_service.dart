import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/water_source.dart';
import '../../models/measurement.dart';
import '../../models/device.dart';
import '../../models/alert_item.dart';

/// Manages demo mode state, seeded datasets for 3 water sources,
/// 7 days of realistic historical telemetry, 1 designated anomaly alert,
/// and live ESP32 telemetry simulation (reading emitted every 10 seconds).
class DemoSimulatorService {
  static DemoSimulatorService? _instance;
  static DemoSimulatorService get instance => _instance ??= DemoSimulatorService._();

  Timer? _liveTelemetryTimer;
  final Random _random = Random();

  final ValueNotifier<bool> isDemoActiveNotifier = ValueNotifier<bool>(false);
  final StreamController<Measurement> _liveMeasurementStreamController =
      StreamController<Measurement>.broadcast();

  Stream<Measurement> get liveMeasurementStream => _liveMeasurementStreamController.stream;

  DemoSimulatorService._();

  bool get isDemoActive => isDemoActiveNotifier.value;

  void startDemoMode({
    required Function(Measurement) onNewLiveReading,
  }) {
    isDemoActiveNotifier.value = true;
    _liveTelemetryTimer?.cancel();

    // Emit live device reading every 10 seconds
    _liveTelemetryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final newReading = _generateLiveDeviceReading();
      _liveMeasurementStreamController.add(newReading);
      onNewLiveReading(newReading);
    });
  }

  void stopDemoMode() {
    isDemoActiveNotifier.value = false;
    _liveTelemetryTimer?.cancel();
    _liveTelemetryTimer = null;
  }

  /// Generates the 3 mandatory realistic demo water sources:
  /// - A River ("Blue River")
  /// - A Well ("Pine Valley Well")
  /// - A Reservoir ("Emerald Lake Reservoir")
  static List<WaterSource> getDemoSources() {
    final now = DateTime.now();
    return [
      WaterSource(
        id: 'demo_src_river',
        name: 'Blue River Reach',
        type: WaterSourceType.river,
        latitude: 6.9380,
        longitude: 79.8720,
        createdBy: 'demo_admin',
        createdAt: now.subtract(const Duration(days: 30)),
        lastReadingAt: now.subtract(const Duration(minutes: 1)),
        ph: 7.15,
        tdsEc: 345.0,
        turbidity: 18.5, // Anomaly spike
        temperature: 28.2,
        status: WaterQualityStatus.unusual, // Flagged due to turbidity anomaly
        description:
            'Continuous stream monitoring along the eastern riverbank. Real-time ESP32 node attached.',
      ),
      WaterSource(
        id: 'demo_src_well',
        name: 'Pine Valley Well',
        type: WaterSourceType.well,
        latitude: 6.9150,
        longitude: 79.8550,
        createdBy: 'demo_admin',
        createdAt: now.subtract(const Duration(days: 60)),
        lastReadingAt: now.subtract(const Duration(minutes: 4)),
        ph: 6.85,
        tdsEc: 420.0,
        turbidity: 2.1,
        temperature: 26.5,
        status: WaterQualityStatus.withinTypicalRange,
        description:
            'Deep groundwater borehole monitored for seasonal mineral conductivity variations.',
      ),
      WaterSource(
        id: 'demo_src_reservoir',
        name: 'Emerald Lake Reservoir',
        type: WaterSourceType.reservoir,
        latitude: 6.9450,
        longitude: 79.8650,
        createdBy: 'demo_admin',
        createdAt: now.subtract(const Duration(days: 90)),
        lastReadingAt: now.subtract(const Duration(minutes: 6)),
        ph: 7.42,
        tdsEc: 280.0,
        turbidity: 1.8,
        temperature: 27.0,
        status: WaterQualityStatus.withinTypicalRange,
        description:
            'Regional impoundment reservoir for ambient community surface water quality monitoring.',
      ),
    ];
  }

  /// Generates 7 days of realistic chronological readings for the 3 sources
  static List<Measurement> getDemoMeasurements() {
    final List<Measurement> measurements = [];
    final now = DateTime.now();

    final sources = [
      {'id': 'demo_src_river', 'lat': 6.9380, 'lng': 79.8720, 'basePh': 7.15, 'baseTds': 340.0, 'baseTurb': 3.2, 'baseTemp': 28.0},
      {'id': 'demo_src_well', 'lat': 6.9150, 'lng': 79.8550, 'basePh': 6.85, 'baseTds': 420.0, 'baseTurb': 2.0, 'baseTemp': 26.5},
      {'id': 'demo_src_reservoir', 'lat': 6.9450, 'lng': 79.8650, 'basePh': 7.42, 'baseTds': 280.0, 'baseTurb': 1.8, 'baseTemp': 27.0},
    ];

    // Generate 7 days at 6-hour intervals = 28 points per source
    for (int day = 7; day >= 0; day--) {
      for (int hour = 0; hour < 24; hour += 6) {
        final time = now.subtract(Duration(days: day, hours: 24 - hour));

        for (final s in sources) {
          final sId = s['id'] as String;
          final basePh = s['basePh'] as double;
          final baseTds = s['baseTds'] as double;
          final baseTurb = s['baseTurb'] as double;
          final baseTemp = s['baseTemp'] as double;
          final lat = s['lat'] as double;
          final lng = s['lng'] as double;

          // Diurnal temperature oscillation (higher midday)
          final hourFactor = sin((hour - 6) / 24 * 2 * pi);
          final temp = baseTemp + (hourFactor * 1.5) + ((day % 3) * 0.2);
          final ph = basePh + (sin(hour / 12 * pi) * 0.12);
          final tds = baseTds + ((day * 2.5) % 15) - 7;
          double turb = baseTurb + (cos(hour / 6 * pi) * 0.4);

          // Insert 1 distinct anomaly on the river at the latest point
          final isAnomalyPoint = (sId == 'demo_src_river' && day == 0 && hour >= 18);
          if (isAnomalyPoint) {
            turb = 18.5; // Distinct spike exceeding fixed threshold 15.0 NTU
          }

          measurements.add(
            Measurement(
              id: 'demo_m_${sId}_${time.millisecondsSinceEpoch}',
              sourceId: sId,
              deviceId: 'esp32_node_${sId.split('_').last}',
              ph: double.parse(ph.toStringAsFixed(2)),
              tdsEc: double.parse(tds.toStringAsFixed(1)),
              turbidity: double.parse(turb.toStringAsFixed(1)),
              temperature: double.parse(temp.toStringAsFixed(1)),
              latitude: lat + (0.0001 * (day % 3)),
              longitude: lng + (0.0001 * (hour % 4)),
              timestamp: time,
              submittedBy: 'ESP32 Device Node',
              source: 'device',
              syncedAt: time,
              notes: isAnomalyPoint ? 'Automatic anomaly detection trigger recorded' : null,
            ),
          );
        }
      }
    }

    return measurements;
  }

  /// Generates the single designated anomaly alert for the demo
  static List<AlertItem> getDemoAlerts() {
    final now = DateTime.now();
    return [
      AlertItem(
        id: 'demo_alt_01',
        sourceId: 'demo_src_river',
        measurementId: 'demo_m_demo_src_river_anomaly',
        parameter: 'Turbidity',
        value: 18.5,
        message: 'Unusual water-quality measurement detected at this location.',
        createdAt: now.subtract(const Duration(minutes: 8)),
        acknowledged: false,
        waterSourceName: 'Blue River Reach',
        severity: WaterQualityStatus.unusual,
        investigationAdvice:
            'Turbidity jumped to 18.5 NTU (+15.3 NTU from preceding sample). Field inspection recommended.',
      ),
    ];
  }

  /// Generates the demo devices
  static List<Device> getDemoDevices() {
    final now = DateTime.now();
    return [
      Device(
        id: 'esp32_demo_node_01',
        name: 'ESP32 River Station (Online)',
        ownerUid: 'demo_user',
        lastSeenAt: now.subtract(const Duration(seconds: 12)),
        batteryLevel: 94,
        signalStrength: -62,
        firmwareVersion: 'v2.1.0-esp32-gps',
      ),
      Device(
        id: 'esp32_demo_node_02',
        name: 'ESP32 Well Monitor (Online)',
        ownerUid: 'demo_user',
        lastSeenAt: now.subtract(const Duration(minutes: 4)),
        batteryLevel: 88,
        signalStrength: -70,
        firmwareVersion: 'v2.1.0-esp32-gps',
      ),
      Device(
        id: 'esp32_demo_node_03',
        name: 'ESP32 Reservoir Station (Offline)',
        ownerUid: 'demo_user',
        lastSeenAt: now.subtract(const Duration(minutes: 45)), // > 10m is offline
        batteryLevel: 22,
        signalStrength: -85,
        firmwareVersion: 'v2.0.8-esp32',
      ),
    ];
  }

  Measurement _generateLiveDeviceReading() {
    final now = DateTime.now();
    final phVariance = (_random.nextDouble() - 0.5) * 0.08;
    final tempVariance = (_random.nextDouble() - 0.5) * 0.15;
    final turbVariance = (_random.nextDouble() - 0.5) * 0.2;
    final tdsVariance = (_random.nextDouble() - 0.5) * 2.0;

    return Measurement(
      id: 'demo_live_${now.millisecondsSinceEpoch}',
      sourceId: 'demo_src_river',
      deviceId: 'esp32_demo_node_01',
      ph: double.parse((7.18 + phVariance).toStringAsFixed(2)),
      tdsEc: double.parse((344.0 + tdsVariance).toStringAsFixed(1)),
      turbidity: double.parse((3.3 + turbVariance).toStringAsFixed(1)),
      temperature: double.parse((28.3 + tempVariance).toStringAsFixed(1)),
      latitude: 6.9380 + ((_random.nextDouble() - 0.5) * 0.0002),
      longitude: 79.8720 + ((_random.nextDouble() - 0.5) * 0.0002),
      timestamp: now,
      submittedBy: 'ESP32 Live Stream',
      source: 'device',
      syncedAt: now,
      notes: 'Live periodic 10-second telemetry packet',
    );
  }
}
