import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Standalone seed script for AquaGuard Demo Mode.
/// 
/// Seeds realistic water-quality dataset:
/// - 3 monitored sources: River, Well, and Reservoir
/// - 7 days of continuous readings (diurnal cycle)
/// - 1 anomaly alert (Turbidity jump to 18.5 NTU on River)
/// - 3 ESP32 hardware device nodes (2 online, 1 offline)
/// 
/// All documents use the separate Firestore collection prefix ("demo_"):
/// - demo_sources
/// - demo_measurements
/// - demo_devices
/// - demo_alerts
/// 
/// Usage:
///   dart run scripts/seed_demo_data.dart
void main(List<String> args) async {
  stdout.writeln('========================================================');
  stdout.writeln('  AquaGuard - IoT Smart Water Quality Seeding Script    ');
  stdout.writeln('========================================================');
  stdout.writeln('Target Firestore Collection Prefix: demo_');
  stdout.writeln('Generating realistic 7-day telemetry dataset...');

  final now = DateTime.now().toUtc();

  // 1. Monitored Water Sources
  final sources = [
    {
      'id': 'demo_src_river',
      'name': 'Blue River Reach',
      'type': 'river',
      'latitude': 6.9380,
      'longitude': 79.8720,
      'createdBy': 'demo_seed_admin',
      'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
      'lastReadingAt': now.subtract(const Duration(minutes: 1)).toIso8601String(),
      'ph': 7.15,
      'tdsEc': 345.0,
      'turbidity': 18.5, // Anomaly spike
      'temperature': 28.2,
      'status': 'unusual',
      'description': 'Continuous stream monitoring station along the eastern riverbank.',
    },
    {
      'id': 'demo_src_well',
      'name': 'Pine Valley Well',
      'type': 'well',
      'latitude': 6.9150,
      'longitude': 79.8550,
      'createdBy': 'demo_seed_admin',
      'createdAt': now.subtract(const Duration(days: 60)).toIso8601String(),
      'lastReadingAt': now.subtract(const Duration(minutes: 4)).toIso8601String(),
      'ph': 6.85,
      'tdsEc': 420.0,
      'turbidity': 2.1,
      'temperature': 26.5,
      'status': 'withinTypicalRange',
      'description': 'Deep groundwater community borehole monitored for seasonal mineral variations.',
    },
    {
      'id': 'demo_src_reservoir',
      'name': 'Emerald Lake Reservoir',
      'type': 'reservoir',
      'latitude': 6.9450,
      'longitude': 79.8650,
      'createdBy': 'demo_seed_admin',
      'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(),
      'lastReadingAt': now.subtract(const Duration(minutes: 6)).toIso8601String(),
      'ph': 7.42,
      'tdsEc': 280.0,
      'turbidity': 1.8,
      'temperature': 27.0,
      'status': 'withinTypicalRange',
      'description': 'Regional impoundment reservoir for ambient community water quality monitoring.',
    },
  ];

  // 2. Generate 7 Days of Measurements (Every 6 hours)
  final measurements = <Map<String, dynamic>>[];
  final sourceConfigs = [
    {'id': 'demo_src_river', 'lat': 6.9380, 'lng': 79.8720, 'basePh': 7.15, 'baseTds': 340.0, 'baseTurb': 3.2, 'baseTemp': 28.0},
    {'id': 'demo_src_well', 'lat': 6.9150, 'lng': 79.8550, 'basePh': 6.85, 'baseTds': 420.0, 'baseTurb': 2.0, 'baseTemp': 26.5},
    {'id': 'demo_src_reservoir', 'lat': 6.9450, 'lng': 79.8650, 'basePh': 7.42, 'baseTds': 280.0, 'baseTurb': 1.8, 'baseTemp': 27.0},
  ];

  for (int day = 7; day >= 0; day--) {
    for (int hour = 0; hour < 24; hour += 6) {
      final sampleTime = now.subtract(Duration(days: day, hours: 24 - hour));

      for (final cfg in sourceConfigs) {
        final sId = cfg['id'] as String;
        final basePh = cfg['basePh'] as double;
        final baseTds = cfg['baseTds'] as double;
        final baseTurb = cfg['baseTurb'] as double;
        final baseTemp = cfg['baseTemp'] as double;
        final lat = cfg['lat'] as double;
        final lng = cfg['lng'] as double;

        // Daily cycle curve
        final hourFactor = sin((hour - 6) / 24 * 2 * pi);
        final temp = baseTemp + (hourFactor * 1.5) + ((day % 3) * 0.2);
        final ph = basePh + (sin(hour / 12 * pi) * 0.12);
        final tds = baseTds + ((day * 2.5) % 15) - 7;
        double turb = baseTurb + (cos(hour / 6 * pi) * 0.4);

        final isAnomaly = (sId == 'demo_src_river' && day == 0 && hour >= 18);
        if (isAnomaly) {
          turb = 18.5; // Turbidity anomaly jump
        }

        measurements.add({
          'id': 'demo_m_${sId}_${sampleTime.millisecondsSinceEpoch}',
          'sourceId': sId,
          'deviceId': 'esp32_${sId.split('_').last}',
          'ph': double.parse(ph.toStringAsFixed(2)),
          'tdsEc': double.parse(tds.toStringAsFixed(1)),
          'turbidity': double.parse(turb.toStringAsFixed(1)),
          'temperature': double.parse(temp.toStringAsFixed(1)),
          'latitude': lat + (0.0001 * (day % 3)),
          'longitude': lng + (0.0001 * (hour % 4)),
          'timestamp': sampleTime.toIso8601String(),
          'submittedBy': 'ESP32 Hardware Node',
          'source': 'device',
          'syncedAt': sampleTime.toIso8601String(),
          'notes': isAnomaly ? 'Unusual turbidity spike logged' : null,
        });
      }
    }
  }

  // 3. Alerts: Single designated anomaly alert
  final alerts = [
    {
      'id': 'demo_alt_01',
      'sourceId': 'demo_src_river',
      'measurementId': 'demo_m_demo_src_river_anomaly',
      'parameter': 'Turbidity',
      'value': 18.5,
      'message': 'Unusual water-quality measurement detected at this location.',
      'createdAt': now.subtract(const Duration(minutes: 8)).toIso8601String(),
      'acknowledged': false,
      'waterSourceName': 'Blue River Reach',
      'severity': 'unusual',
    },
  ];

  // 4. ESP32 Devices
  final devices = [
    {
      'id': 'esp32_demo_node_01',
      'name': 'ESP32 River Station (Online)',
      'ownerUid': 'demo_admin',
      'lastSeenAt': now.subtract(const Duration(seconds: 12)).toIso8601String(),
      'batteryLevel': 94,
      'signalStrength': -62,
      'firmwareVersion': 'v2.1.0-esp32-gps',
    },
    {
      'id': 'esp32_demo_node_02',
      'name': 'ESP32 Well Monitor (Online)',
      'ownerUid': 'demo_admin',
      'lastSeenAt': now.subtract(const Duration(minutes: 4)).toIso8601String(),
      'batteryLevel': 88,
      'signalStrength': -70,
      'firmwareVersion': 'v2.1.0-esp32-gps',
    },
    {
      'id': 'esp32_demo_node_03',
      'name': 'ESP32 Reservoir Station (Offline)',
      'ownerUid': 'demo_admin',
      'lastSeenAt': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      'batteryLevel': 22,
      'signalStrength': -85,
      'firmwareVersion': 'v2.0.8-esp32',
    },
  ];

  final fullSeedPayload = {
    'generatedAt': now.toIso8601String(),
    'collections': {
      'demo_sources': sources,
      'demo_measurements': measurements,
      'demo_alerts': alerts,
      'demo_devices': devices,
    },
  };

  // Write demo seed payload to disk for local mock & direct Firestore import
  final outputDir = Directory('.storage');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final seedFile = File('.storage/demo_seed_export.json');
  seedFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(fullSeedPayload),
  );

  stdout.writeln('--------------------------------------------------------');
  stdout.writeln('SUCCESS: Seed dataset generated.');
  stdout.writeln('  Sources:      ${sources.length} (River, Well, Reservoir)');
  stdout.writeln('  Measurements: ${measurements.length} (7 days chronological)');
  stdout.writeln('  Alerts:       ${alerts.length} (Turbidity anomaly: 18.5 NTU)');
  stdout.writeln('  Devices:      ${devices.length} (2 Online <10m, 1 Offline >10m)');
  stdout.writeln('Export file:    ${seedFile.path}');
  stdout.writeln('--------------------------------------------------------');
  stdout.writeln('To import directly into Firebase Firestore:');
  stdout.writeln('  1. Deploy security rules: firebase deploy --only firestore:rules');
  stdout.writeln('  2. Use firebase-admin or Firestore REST API to push the generated JSON');
  stdout.writeln('     documents under the "demo_" collection prefix.');
  stdout.writeln('========================================================');
}
