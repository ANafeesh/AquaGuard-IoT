import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../data/mock_data.dart';
import '../../models/measurement.dart';
import '../../models/reading_log_entry.dart';
import '../../models/water_source.dart';
import '../reading_repository.dart';

class FirebaseReadingRepository implements ReadingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConfig.getMeasurementsCollection());

  @override
  Stream<List<ParameterReading>> watchLatestReadings(String waterSourceId) {
    Query<Map<String, dynamic>> query = _collection;
    if (waterSourceId.isNotEmpty) {
      query = query.where('sourceId', isEqualTo: waterSourceId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final ph = (data['ph'] as num?)?.toDouble() ?? 7.0;
        final tds = (data['tdsEc'] as num?)?.toDouble() ??
            (data['tds'] as num?)?.toDouble() ??
            250.0;
        final turb = (data['turbidity'] as num?)?.toDouble() ?? 2.0;
        final temp = (data['temperature'] as num?)?.toDouble() ?? 25.0;

        return [
          ParameterReading.fromType(type: ParameterType.ph, value: ph),
          ParameterReading.fromType(type: ParameterType.tds, value: tds),
          ParameterReading.fromType(type: ParameterType.turbidity, value: turb),
          ParameterReading.fromType(type: ParameterType.temperature, value: temp),
        ];
      }

      // Default baseline readings if source has not yet received telemetry
      return [
        ParameterReading.fromType(type: ParameterType.ph, value: 7.2),
        ParameterReading.fromType(type: ParameterType.tds, value: 310.0),
        ParameterReading.fromType(type: ParameterType.turbidity, value: 2.8),
        ParameterReading.fromType(type: ParameterType.temperature, value: 27.5),
      ];
    });
  }

  @override
  Stream<List<ReadingLogEntry>> watchReadingLogs(String waterSourceId) {
    Query<Map<String, dynamic>> query = _collection;
    if (waterSourceId.isNotEmpty) {
      query = query.where('sourceId', isEqualTo: waterSourceId);
    }

    return query
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] != null
            ? DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now();

        return ReadingLogEntry(
          id: doc.id,
          waterSourceId: data['sourceId'] as String? ?? waterSourceId,
          waterSourceName: data['waterSourceName'] as String? ?? 'Water Source',
          timestamp: timestamp,
          ph: (data['ph'] as num?)?.toDouble() ?? 7.0,
          tds: (data['tdsEc'] as num?)?.toInt() ??
              (data['tds'] as num?)?.toInt() ??
              250,
          turbidity: (data['turbidity'] as num?)?.toDouble() ?? 2.0,
          temperature: (data['temperature'] as num?)?.toDouble() ?? 25.0,
          status: WaterQualityStatus.values.firstWhere(
            (e) => e.name == data['status'],
            orElse: () => WaterQualityStatus.withinTypicalRange,
          ),
          notes: data['notes'] as String? ?? 'Automated telemetry snapshot recorded.',
        );
      }).toList();
    });
  }

  @override
  Future<void> addReadingEntry(ReadingLogEntry entry) async {
    final docRef = _collection.doc(entry.id);
    await docRef.set({
      'id': entry.id,
      'sourceId': entry.waterSourceId,
      'waterSourceName': entry.waterSourceName,
      'ph': entry.ph,
      'tdsEc': entry.tds.toDouble(),
      'turbidity': entry.turbidity,
      'temperature': entry.temperature,
      'timestamp': entry.timestamp.toIso8601String(),
      'status': entry.status.name,
      'notes': entry.notes,
      'source': 'community',
      'syncedAt': DateTime.now().toIso8601String(),
    });

    // Also update the source document's lastReadingAt and latest values
    try {
      final sourceDoc = _firestore
          .collection(AppConfig.getSourcesCollection())
          .doc(entry.waterSourceId);
      await sourceDoc.update({
        'lastReadingAt': entry.timestamp.toIso8601String(),
        'ph': entry.ph,
        'tdsEc': entry.tds.toDouble(),
        'turbidity': entry.turbidity,
        'temperature': entry.temperature,
      });
    } catch (_) {}
  }

  @override
  Future<Map<String, List<HistoricalPoint>>> getHistoricalTrends(
    String waterSourceId,
    ParameterType param,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _collection;
      if (waterSourceId.isNotEmpty) {
        query = query.where('sourceId', isEqualTo: waterSourceId);
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final now = DateTime.now();
        final points24h = <HistoricalPoint>[];
        final points7d = <HistoricalPoint>[];
        final points30d = <HistoricalPoint>[];
        final pointsAll = <HistoricalPoint>[];

        for (final doc in snapshot.docs.reversed) {
          final data = doc.data();
          final dt = data['timestamp'] != null
              ? DateTime.tryParse(data['timestamp'].toString()) ?? now
              : now;

          double val;
          switch (param) {
            case ParameterType.ph:
              val = (data['ph'] as num?)?.toDouble() ?? 7.0;
              break;
            case ParameterType.tds:
              val = (data['tdsEc'] as num?)?.toDouble() ??
                  (data['tds'] as num?)?.toDouble() ??
                  250.0;
              break;
            case ParameterType.turbidity:
              val = (data['turbidity'] as num?)?.toDouble() ?? 2.0;
              break;
            case ParameterType.temperature:
              val = (data['temperature'] as num?)?.toDouble() ?? 25.0;
              break;
          }

          final diff = now.difference(dt);
          final timeLabel = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          final point = HistoricalPoint(timeLabel, val, dt);

          if (diff.inHours <= 24) points24h.add(point);
          if (diff.inDays <= 7) points7d.add(point);
          if (diff.inDays <= 30) points30d.add(point);
          pointsAll.add(point);
        }

        return {
          '24h': points24h.isNotEmpty ? points24h : pointsAll,
          '7d': points7d.isNotEmpty ? points7d : pointsAll,
          '30d': points30d.isNotEmpty ? points30d : pointsAll,
          'all': pointsAll,
        };
      }
    } catch (_) {}

    // Fallback to pre-generated historical trend curves if no Firestore samples yet
    switch (param) {
      case ParameterType.ph:
        return MockData.phTrends;
      case ParameterType.tds:
        return MockData.tdsTrends;
      case ParameterType.turbidity:
        return MockData.turbidityTrends;
      case ParameterType.temperature:
        return MockData.tempTrends;
    }
  }

  @override
  Future<Map<String, dynamic>> getReadingDelta(
    String waterSourceId,
    ParameterType param,
  ) async {
    try {
      Query<Map<String, dynamic>> query = _collection;
      if (waterSourceId.isNotEmpty) {
        query = query.where('sourceId', isEqualTo: waterSourceId);
      }

      final snapshot = await query
          .orderBy('timestamp', descending: true)
          .limit(2)
          .get();

      if (snapshot.docs.length >= 2) {
        final d1 = snapshot.docs[0].data();
        final d2 = snapshot.docs[1].data();

        double getParamVal(Map<String, dynamic> d) {
          switch (param) {
            case ParameterType.ph:
              return (d['ph'] as num?)?.toDouble() ?? 7.0;
            case ParameterType.tds:
              return (d['tdsEc'] as num?)?.toDouble() ??
                  (d['tds'] as num?)?.toDouble() ??
                  250.0;
            case ParameterType.turbidity:
              return (d['turbidity'] as num?)?.toDouble() ?? 2.0;
            case ParameterType.temperature:
              return (d['temperature'] as num?)?.toDouble() ?? 25.0;
          }
        }

        final latestVal = getParamVal(d1);
        final prevVal = getParamVal(d2);
        final diff = latestVal - prevVal;
        final changeStr = diff == 0
            ? '0.0'
            : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}';

        return {
          'latest': latestVal.toStringAsFixed(1),
          'previous': prevVal.toStringAsFixed(1),
          'change': changeStr,
          'isPositive': diff <= 0,
        };
      }
    } catch (_) {}

    return {
      'latest': '7.2',
      'previous': '7.1',
      'change': '+0.1',
      'isPositive': true,
    };
  }
}
