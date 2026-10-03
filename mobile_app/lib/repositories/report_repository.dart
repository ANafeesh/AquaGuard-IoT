import '../models/community_observation.dart';

abstract class ReportRepository {
  /// Stream community observations
  Stream<List<CommunityObservation>> watchObservations();

  /// Submit a new water observation
  Future<void> submitObservation(CommunityObservation observation);

  /// Fetch user-submitted observations count
  Future<int> getUserObservationsCount(String userId);

  /// Upvote or verify a community observation
  Future<void> upvoteObservation(String observationId);

  /// Delete an observation (e.g. from My Observations)
  Future<void> deleteObservation(String observationId);

  /// Update observation note
  Future<void> updateObservationNote(String observationId, String newNote);
}
