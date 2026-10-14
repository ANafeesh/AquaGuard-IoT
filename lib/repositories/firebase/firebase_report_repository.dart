import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../models/community_observation.dart';
import '../../data/mock_data.dart';
import '../report_repository.dart';

class FirebaseReportRepository implements ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConfig.observationsCollection);

  @override
  Stream<List<CommunityObservation>> watchObservations() async* {
    // 1. Instantly yield baseline observations (0ms delay)
    yield MockData.observations;

    // 2. Stream live observations from Firestore
    yield* _collection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return CommunityObservation.fromJson(data);
        }).toList();
      }
      return MockData.observations;
    }).handleError((_) => MockData.observations);
  }

  @override
  Future<void> submitObservation(CommunityObservation observation) async {
    await _collection.doc(observation.id).set(observation.toJson());
  }

  @override
  Future<int> getUserObservationsCount(String userId) async {
    try {
      final snapshot = await _collection
          .where('userName', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> upvoteObservation(String observationId) async {
    await _collection.doc(observationId).update({
      'helpfulCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> deleteObservation(String observationId) async {
    await _collection.doc(observationId).delete();
  }

  @override
  Future<void> updateObservationNote(String observationId, String newNote) async {
    await _collection.doc(observationId).update({
      'notes': newNote,
    });
  }
}
