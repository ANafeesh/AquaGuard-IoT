import 'dart:async';
import '../../models/community_observation.dart';
import '../../data/mock_data.dart';
import '../../services/local_storage_service.dart';
import '../report_repository.dart';

class MockReportRepository implements ReportRepository {
  static const String _storageKey = 'aquaguard_observations';
  final _controller = StreamController<List<CommunityObservation>>.broadcast();
  final List<CommunityObservation> _observations = [];

  MockReportRepository() {
    _loadObservations();
  }

  void _loadObservations() {
    final cached = LocalStorageService.instance.getJsonList(_storageKey);
    if (cached.isNotEmpty) {
      _observations.addAll(cached.map((j) => CommunityObservation.fromJson(j)));
    } else {
      _observations.addAll(MockData.observations);
    }
    _controller.add(_observations);
  }

  Future<void> _persist() async {
    await LocalStorageService.instance.setJsonList(
      _storageKey,
      _observations.map((o) => o.toJson()).toList(),
    );
  }

  @override
  Stream<List<CommunityObservation>> watchObservations() async* {
    yield _observations;
    yield* _controller.stream;
  }

  @override
  Future<void> submitObservation(CommunityObservation observation) async {
    _observations.insert(0, observation);
    _controller.add(List.unmodifiable(_observations));
    await _persist();
  }

  @override
  Future<int> getUserObservationsCount(String userId) async {
    return _observations.length;
  }

  @override
  Future<void> upvoteObservation(String observationId) async {
    final idx = _observations.indexWhere((o) => o.id == observationId);
    if (idx != -1) {
      final old = _observations[idx];
      _observations[idx] = old.copyWith(helpfulCount: old.helpfulCount + 1);
      _controller.add(List.unmodifiable(_observations));
      await _persist();
    }
  }

  @override
  Future<void> deleteObservation(String observationId) async {
    _observations.removeWhere((o) => o.id == observationId);
    _controller.add(List.unmodifiable(_observations));
    await _persist();
  }

  @override
  Future<void> updateObservationNote(String observationId, String newNote) async {
    final idx = _observations.indexWhere((o) => o.id == observationId);
    if (idx != -1) {
      _observations[idx] = _observations[idx].copyWith(notes: newNote);
      _controller.add(List.unmodifiable(_observations));
      await _persist();
    }
  }
}
