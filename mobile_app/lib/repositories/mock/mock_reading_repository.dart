import 'dart:async';
import '../../models/measurement.dart';
import '../../models/reading_log_entry.dart';
import '../../models/water_source.dart';
import '../../data/mock_data.dart';
import '../../services/local_storage_service.dart';
import '../reading_repository.dart';

class MockReadingRepository implements ReadingRepository {
  static const String _storageKey = 'aquaguard_reading_logs';
  final _logsController = StreamController<List<ReadingLogEntry>>.broadcast();
  final List<ReadingLogEntry> _allLogs = [];

  MockReadingRepository() {
    _loadLogs();
  }

  void _loadLogs() {
    final cached = LocalStorageService.instance.getJsonList(_storageKey);
    if (cached.isNotEmpty) {
      _allLogs.addAll(cached.map((j) => ReadingLogEntry.fromJson(j)));
    } else {
      final now = DateTime.now();
      _allLogs.addAll([
        ReadingLogEntry(
          id: 'log-1',
          waterSourceId: 'ws-1',
          waterSourceName: 'Lake View Point',
          timestamp: now.subtract(const Duration(minutes: 45)),
          ph: 7.2,
          tds: 320,
          turbidity: 3.4,
          temperature: 28.4,
          status: WaterQualityStatus.withinTypicalRange,
          notes: 'Routine automated telemetry reading.',
        ),
        ReadingLogEntry(
          id: 'log-2',
          waterSourceId: 'ws-1',
          waterSourceName: 'Lake View Point',
          timestamp: now.subtract(const Duration(hours: 4, minutes: 15)),
          ph: 7.1,
          tds: 318,
          turbidity: 3.3,
          temperature: 28.1,
          status: WaterQualityStatus.withinTypicalRange,
          notes: 'Morning measurement snapshot.',
        ),
        ReadingLogEntry(
          id: 'log-3',
          waterSourceId: 'ws-1',
          waterSourceName: 'Lake View Point',
          timestamp: now.subtract(const Duration(hours: 14)),
          ph: 7.3,
          tds: 325,
          turbidity: 3.5,
          temperature: 28.6,
          status: WaterQualityStatus.withinTypicalRange,
          notes: 'Evening monitoring cycle.',
        ),
        ReadingLogEntry(
          id: 'log-4',
          waterSourceId: 'ws-1',
          waterSourceName: 'Lake View Point',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
          ph: 7.2,
          tds: 322,
          turbidity: 3.4,
          temperature: 28.3,
          status: WaterQualityStatus.withinTypicalRange,
          notes: 'Prior day verification scan.',
        ),
        // ws-2
        ReadingLogEntry(
          id: 'log-5',
          waterSourceId: 'ws-2',
          waterSourceName: 'Riverside Monitoring Station',
          timestamp: now.subtract(const Duration(minutes: 30)),
          ph: 8.4,
          tds: 580,
          turbidity: 6.8,
          temperature: 29.8,
          status: WaterQualityStatus.unusual,
          notes: 'Elevated turbidity following rainfall upstream.',
        ),
        ReadingLogEntry(
          id: 'log-6',
          waterSourceId: 'ws-2',
          waterSourceName: 'Riverside Monitoring Station',
          timestamp: now.subtract(const Duration(hours: 5)),
          ph: 8.1,
          tds: 540,
          turbidity: 5.9,
          temperature: 29.2,
          status: WaterQualityStatus.unusual,
          notes: 'Pre-rain measurement.',
        ),
      ]);
    }
    _logsController.add(_allLogs);
  }

  Future<void> _persist() async {
    await LocalStorageService.instance.setJsonList(
      _storageKey,
      _allLogs.map((e) => e.toJson()).toList(),
    );
  }

  @override
  Stream<List<ParameterReading>> watchLatestReadings(String waterSourceId) async* {
    // If we have logs for this source, use the latest log to build parameter readings
    final sourceLogs = _allLogs.where((l) => l.waterSourceId == waterSourceId).toList();
    if (sourceLogs.isNotEmpty) {
      final latest = sourceLogs.first;
      yield [
        ParameterReading.fromType(
          type: ParameterType.ph,
          value: latest.ph,
        ),
        ParameterReading.fromType(
          type: ParameterType.tds,
          value: latest.tds.toDouble(),
        ),
        ParameterReading.fromType(
          type: ParameterType.turbidity,
          value: latest.turbidity,
        ),
        ParameterReading.fromType(
          type: ParameterType.temperature,
          value: latest.temperature,
        ),
      ];
    } else {
      yield MockData.getLakeViewReadings();
    }
  }

  @override
  Stream<List<ReadingLogEntry>> watchReadingLogs(String waterSourceId) async* {
    yield _allLogs.where((l) => l.waterSourceId == waterSourceId || waterSourceId.isEmpty).toList();
    yield* _logsController.stream.map(
      (logs) => logs.where((l) => l.waterSourceId == waterSourceId || waterSourceId.isEmpty).toList(),
    );
  }

  @override
  Future<void> addReadingEntry(ReadingLogEntry entry) async {
    _allLogs.insert(0, entry);
    _logsController.add(List.unmodifiable(_allLogs));
    await _persist();
  }

  @override
  Future<Map<String, List<HistoricalPoint>>> getHistoricalTrends(
    String waterSourceId,
    ParameterType param,
  ) async {
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
    final sourceLogs = _allLogs.where((l) => l.waterSourceId == waterSourceId).toList();
    if (sourceLogs.length >= 2) {
      final latestEntry = sourceLogs[0];
      final previousEntry = sourceLogs[1];

      double latestVal;
      double prevVal;

      switch (param) {
        case ParameterType.ph:
          latestVal = latestEntry.ph;
          prevVal = previousEntry.ph;
          break;
        case ParameterType.tds:
          latestVal = latestEntry.tds.toDouble();
          prevVal = previousEntry.tds.toDouble();
          break;
        case ParameterType.turbidity:
          latestVal = latestEntry.turbidity;
          prevVal = previousEntry.turbidity;
          break;
        case ParameterType.temperature:
          latestVal = latestEntry.temperature;
          prevVal = previousEntry.temperature;
          break;
      }

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
    } else if (sourceLogs.isNotEmpty) {
      final latestEntry = sourceLogs[0];
      double latestVal;
      switch (param) {
        case ParameterType.ph:
          latestVal = latestEntry.ph;
          break;
        case ParameterType.tds:
          latestVal = latestEntry.tds.toDouble();
          break;
        case ParameterType.turbidity:
          latestVal = latestEntry.turbidity;
          break;
        case ParameterType.temperature:
          latestVal = latestEntry.temperature;
          break;
      }
      return {
        'latest': latestVal.toStringAsFixed(1),
        'previous': '--',
        'change': 'Baseline',
        'isPositive': true,
      };
    }

    switch (param) {
      case ParameterType.ph:
        return {'latest': '7.2', 'previous': '7.1', 'change': '+0.1', 'isPositive': true};
      case ParameterType.tds:
        return {'latest': '320', 'previous': '318', 'change': '+2', 'isPositive': true};
      case ParameterType.turbidity:
        return {'latest': '3.4', 'previous': '3.3', 'change': '+0.1', 'isPositive': false};
      case ParameterType.temperature:
        return {'latest': '28.4', 'previous': '28.1', 'change': '+0.3', 'isPositive': false};
    }
  }
}
