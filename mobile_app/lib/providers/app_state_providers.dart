import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../models/alert_item.dart';
import '../models/community_observation.dart';
import '../models/reading_log_entry.dart';
import '../repositories/auth_repository.dart';
import 'repository_providers.dart';

/// Stream of all monitored water sources
final waterSourcesStreamProvider = StreamProvider<List<WaterSource>>((ref) {
  final repo = ref.watch(waterSourceRepositoryProvider);
  return repo.watchWaterSources();
});

/// Notifier for currently selected water source ID
class SelectedSourceIdNotifier extends Notifier<String> {
  @override
  String build() => 'ws-1';

  void setSourceId(String id) {
    state = id;
  }
}

final selectedSourceIdProvider =
    NotifierProvider<SelectedSourceIdNotifier, String>(SelectedSourceIdNotifier.new);

/// Currently active water source object
final activeWaterSourceProvider = Provider<WaterSource?>((ref) {
  final sourcesAsync = ref.watch(waterSourcesStreamProvider);
  final selectedId = ref.watch(selectedSourceIdProvider);

  return sourcesAsync.when(
    data: (sources) => sources.firstWhere(
      (s) => s.id == selectedId,
      orElse: () => sources.first,
    ),
    loading: () => null,
    error: (err, stack) => null,
  );
});

/// Stream of latest readings for a given water source
final latestReadingsProvider =
    StreamProvider.family<List<ParameterReading>, String>((ref, sourceId) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchLatestReadings(sourceId);
});

/// Stream of alerts
final alertsStreamProvider = StreamProvider<List<AlertItem>>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return repo.watchAlerts();
});

/// Stream of unread alerts count
final unreadAlertsCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return repo.watchUnreadCount();
});

/// Stream of community observations
final observationsStreamProvider = StreamProvider<List<CommunityObservation>>((ref) {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.watchObservations();
});

/// Stream of current authenticated user
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.watchCurrentUser();
});

/// Stream of historical reading logs for a given water source
final readingLogsStreamProvider =
    StreamProvider.family<List<ReadingLogEntry>, String>((ref, sourceId) {
  final repo = ref.watch(readingRepositoryProvider);
  return repo.watchReadingLogs(sourceId);
});
