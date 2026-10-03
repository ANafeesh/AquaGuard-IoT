import '../../models/community_observation.dart';
import '../report_repository.dart';

class FirebaseReportRepository implements ReportRepository {
  @override
  Stream<List<CommunityObservation>> watchObservations() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> submitObservation(CommunityObservation observation) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<int> getUserObservationsCount(String userId) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> upvoteObservation(String observationId) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> deleteObservation(String observationId) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> updateObservationNote(String observationId, String newNote) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }
}
