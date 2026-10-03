import '../../models/measurement.dart';
import '../../models/reading_log_entry.dart';
import '../reading_repository.dart';

class FirebaseReadingRepository implements ReadingRepository {
  @override
  Stream<List<ParameterReading>> watchLatestReadings(String waterSourceId) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<Map<String, List<HistoricalPoint>>> getHistoricalTrends(
    String waterSourceId,
    ParameterType param,
  ) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<Map<String, dynamic>> getReadingDelta(
    String waterSourceId,
    ParameterType param,
  ) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Stream<List<ReadingLogEntry>> watchReadingLogs(String waterSourceId) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> addReadingEntry(ReadingLogEntry entry) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }
}
