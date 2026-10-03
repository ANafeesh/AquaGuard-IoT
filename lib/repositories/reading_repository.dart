import '../models/measurement.dart';
import '../models/reading_log_entry.dart';

abstract class ReadingRepository {
  /// Stream latest parameter readings for a given water source
  Stream<List<ParameterReading>> watchLatestReadings(String waterSourceId);

  /// Fetch historical trend data points for chart rendering
  Future<Map<String, List<HistoricalPoint>>> getHistoricalTrends(
    String waterSourceId,
    ParameterType param,
  );

  /// Get reading delta comparisons (latest, previous, change)
  Future<Map<String, dynamic>> getReadingDelta(
    String waterSourceId,
    ParameterType param,
  );

  /// Stream historical reading log entries for a given water source
  Stream<List<ReadingLogEntry>> watchReadingLogs(String waterSourceId);

  /// Add a new reading entry (from telemetry or user observation)
  Future<void> addReadingEntry(ReadingLogEntry entry);
}
