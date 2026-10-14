import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../models/water_source.dart';
import '../models/device.dart';
import '../models/alert_item.dart';
import '../models/community_observation.dart';

class FirebaseSeedService {
  static final FirebaseSeedService instance = FirebaseSeedService._();
  FirebaseSeedService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if the connected Firestore has any sources already
  Future<int> getSourceCount() async {
    try {
      final snap = await _firestore.collection(AppConfig.sourcesCollection).get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('[FirebaseSeedService] Error checking sources count: $e');
      return 0;
    }
  }

  /// Seeds realistic water-quality data directly into Firestore
  Future<void> seedSampleDataToFirebase({Function(String status)? onProgress}) async {
    final now = DateTime.now().toUtc();
    final random = Random();

    onProgress?.call('Seeding water sources...');

    // 1. Water Sources
    final sources = [
      WaterSource(
        id: 'src_lake_01',
        name: 'Lake View Point',
        type: WaterSourceType.lake,
        latitude: 6.9271,
        longitude: 79.8612,
        createdBy: 'system_admin',
        createdAt: now.subtract(const Duration(days: 45)),
        lastReadingAt: now.subtract(const Duration(minutes: 3)),
        ph: 7.25,
        tdsEc: 320.0,
        turbidity: 3.4,
        temperature: 28.2,
        status: WaterQualityStatus.withinTypicalRange,
        description: 'Primary community freshwater lake monitored for ambient aquatic indicators.',
      ),
      WaterSource(
        id: 'src_river_02',
        name: 'Riverside Reach Station',
        type: WaterSourceType.river,
        latitude: 6.9380,
        longitude: 79.8720,
        createdBy: 'system_admin',
        createdAt: now.subtract(const Duration(days: 60)),
        lastReadingAt: now.subtract(const Duration(minutes: 8)),
        ph: 6.90,
        tdsEc: 410.0,
        turbidity: 7.8, // Slightly elevated turbidity
        temperature: 29.1,
        status: WaterQualityStatus.unusual,
        description: 'Slow-flowing river tributary downstream from seasonal runoff channels.',
      ),
      WaterSource(
        id: 'src_well_03',
        name: 'Community Groundwater Well',
        type: WaterSourceType.well,
        latitude: 6.9150,
        longitude: 79.8550,
        createdBy: 'system_admin',
        createdAt: now.subtract(const Duration(days: 90)),
        lastReadingAt: now.subtract(const Duration(minutes: 25)),
        ph: 6.50,
        tdsEc: 460.0,
        turbidity: 2.1,
        temperature: 26.8,
        status: WaterQualityStatus.withinTypicalRange,
        description: 'Deep groundwater community borehole for ambient environmental monitoring.',
      ),
      WaterSource(
        id: 'src_res_04',
        name: 'North Reservoir Basin',
        type: WaterSourceType.reservoir,
        latitude: 6.9450,
        longitude: 79.8650,
        createdBy: 'system_admin',
        createdAt: now.subtract(const Duration(days: 30)),
        lastReadingAt: now.subtract(const Duration(minutes: 5)),
        ph: 7.40,
        tdsEc: 285.0,
        turbidity: 1.8,
        temperature: 27.0,
        status: WaterQualityStatus.withinTypicalRange,
        description: 'Protected catchment basin supplying regional environmental monitoring.',
      ),
    ];

    for (final src in sources) {
      await _firestore
          .collection(AppConfig.sourcesCollection)
          .doc(src.id)
          .set(src.toJson());
    }

    onProgress?.call('Generating 7-day telemetry measurements...');

    // 2. Measurements (7 days history for graphs)
    final sourceConfigs = [
      {'id': 'src_lake_01', 'name': 'Lake View Point', 'basePh': 7.25, 'baseTds': 320.0, 'baseTurb': 3.4, 'baseTemp': 28.2},
      {'id': 'src_river_02', 'name': 'Riverside Reach Station', 'basePh': 6.90, 'baseTds': 410.0, 'baseTurb': 5.2, 'baseTemp': 29.1},
      {'id': 'src_well_03', 'name': 'Community Groundwater Well', 'basePh': 6.50, 'baseTds': 460.0, 'baseTurb': 2.1, 'baseTemp': 26.8},
      {'id': 'src_res_04', 'name': 'North Reservoir Basin', 'basePh': 7.40, 'baseTds': 285.0, 'baseTurb': 1.8, 'baseTemp': 27.0},
    ];

    final batch = _firestore.batch();
    int batchCount = 0;

    for (int day = 7; day >= 0; day--) {
      for (int hour = 0; hour < 24; hour += 4) {
        final sampleTime = now.subtract(Duration(days: day, hours: 24 - hour));

        for (final cfg in sourceConfigs) {
          final sId = cfg['id'] as String;
          final sName = cfg['name'] as String;
          final basePh = cfg['basePh'] as double;
          final baseTds = cfg['baseTds'] as double;
          final baseTurb = cfg['baseTurb'] as double;
          final baseTemp = cfg['baseTemp'] as double;

          final hourFactor = sin((hour - 6) / 24 * 2 * pi);
          final temp = baseTemp + (hourFactor * 1.4) + ((day % 3) * 0.15);
          final ph = basePh + (sin(hour / 12 * pi) * 0.1);
          final tds = baseTds + ((day * 2) % 12) - 6;
          double turb = baseTurb + (cos(hour / 6 * pi) * 0.3);

          final isAnomaly = (sId == 'src_river_02' && day == 0 && hour >= 16);
          if (isAnomaly) {
            turb = 16.5; // Turbidity spike
          }

          final mId = 'm_${sId}_${sampleTime.millisecondsSinceEpoch}';
          final docRef = _firestore.collection(AppConfig.measurementsCollection).doc(mId);

          batch.set(docRef, {
            'id': mId,
            'sourceId': sId,
            'waterSourceName': sName,
            'ph': double.parse(ph.toStringAsFixed(2)),
            'tdsEc': double.parse(tds.toStringAsFixed(1)),
            'turbidity': double.parse(turb.toStringAsFixed(1)),
            'temperature': double.parse(temp.toStringAsFixed(1)),
            'timestamp': sampleTime.toIso8601String(),
            'status': isAnomaly ? 'unusual' : 'withinTypicalRange',
            'notes': isAnomaly ? 'Unusual turbidity spike logged' : 'Automated telemetry snapshot.',
            'source': 'device',
          });

          batchCount++;
          if (batchCount >= 450) {
            await batch.commit();
            batchCount = 0;
          }
        }
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    onProgress?.call('Registering anomaly alerts...');

    // 3. Alerts
    final alerts = [
      AlertItem(
        id: 'alt_spike_river_01',
        sourceId: 'src_river_02',
        waterSourceName: 'Riverside Reach Station',
        parameter: 'Turbidity',
        value: 16.5,
        baseline: 'Below 5.0 NTU',
        severity: AlertSeverity.warning,
        status: WaterQualityStatus.unusual,
        createdAt: now.subtract(const Duration(minutes: 18)),
        acknowledged: false,
        message: 'Unusual water-quality measurement detected at this location.',
      ),
      AlertItem(
        id: 'alt_ph_well_02',
        sourceId: 'src_well_03',
        waterSourceName: 'Community Groundwater Well',
        parameter: 'pH Level',
        value: 6.42,
        baseline: '6.5 – 8.5',
        severity: AlertSeverity.attention,
        status: WaterQualityStatus.unusual,
        createdAt: now.subtract(const Duration(hours: 3)),
        acknowledged: true,
        message: 'Slightly acidic reading outside typical seasonal baseline.',
      ),
    ];

    for (final alt in alerts) {
      await _firestore
          .collection(AppConfig.alertsCollection)
          .doc(alt.id)
          .set(alt.toJson());
    }

    onProgress?.call('Adding community observations...');

    // 4. Observations
    final observations = [
      CommunityObservation(
        id: 'obs_lake_field_01',
        waterSourceName: 'Lake View Point',
        locationArea: 'North Deck Jetty',
        userName: 'Elena Rostova',
        userAvatar: 'ER',
        timeAgo: '15m ago',
        notes: 'Water appears calm and remarkably clear today. No surface algae or floating debris noted.',
        ph: 7.2,
        tds: 318,
        turbidity: 3.2,
        temperature: 28.0,
        status: WaterQualityStatus.withinTypicalRange,
        helpfulCount: 5,
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      CommunityObservation(
        id: 'obs_river_field_02',
        waterSourceName: 'Riverside Reach Station',
        locationArea: 'East Bridge Outflow',
        userName: 'Marcus Chen',
        userAvatar: 'MC',
        timeAgo: '1h ago',
        notes: 'High silt disturbance observed following morning upstream rain. Moderate murky tint.',
        ph: 6.9,
        tds: 412,
        turbidity: 7.8,
        temperature: 28.8,
        status: WaterQualityStatus.unusual,
        helpfulCount: 3,
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
      CommunityObservation(
        id: 'obs_well_field_03',
        waterSourceName: 'Community Groundwater Well',
        locationArea: 'Main Pump House',
        userName: 'Ayesha Perera',
        userAvatar: 'AP',
        timeAgo: '4h ago',
        notes: 'Well pump operational. Clear water pumped with no unusual odor or sediment.',
        ph: 6.6,
        tds: 455,
        turbidity: 2.0,
        temperature: 26.5,
        status: WaterQualityStatus.withinTypicalRange,
        helpfulCount: 8,
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
    ];

    for (final obs in observations) {
      await _firestore
          .collection('observations')
          .doc(obs.id)
          .set(obs.toJson());
    }

    onProgress?.call('Registering ESP32 hardware devices...');

    // 5. Hardware IoT Devices
    final devices = [
      Device(
        id: 'esp32_lake_node_01',
        name: 'ESP32 Lake Station (Online)',
        ownerUid: 'system_admin',
        lastSeenAt: now.subtract(const Duration(minutes: 2)), // Online (<10m)
        batteryLevel: 94,
        signalStrength: -62,
        firmwareVersion: 'v2.1.4-esp32-gps',
      ),
      Device(
        id: 'esp32_river_node_02',
        name: 'ESP32 River Monitor (Online)',
        ownerUid: 'system_admin',
        lastSeenAt: now.subtract(const Duration(minutes: 4)), // Online (<10m)
        batteryLevel: 88,
        signalStrength: -69,
        firmwareVersion: 'v2.1.4-esp32-gps',
      ),
      Device(
        id: 'esp32_res_node_03',
        name: 'ESP32 Reservoir Station (Offline)',
        ownerUid: 'system_admin',
        lastSeenAt: now.subtract(const Duration(minutes: 42)), // Offline (>10m)
        batteryLevel: 18,
        signalStrength: -88,
        firmwareVersion: 'v2.0.8-esp32',
      ),
    ];

    for (final dev in devices) {
      await _firestore
          .collection(AppConfig.devicesCollection)
          .doc(dev.id)
          .set(dev.toJson());
    }

    onProgress?.call('Firebase sample data successfully written!');
  }
}
