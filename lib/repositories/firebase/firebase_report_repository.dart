import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/community_observation.dart';
import '../report_repository.dart';

class FirebaseReportRepository implements ReportRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('observations');

  @override
  Stream<List<CommunityObservation>> watchObservations() {
    return _collection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return CommunityObservation.fromJson(data);
      }).toList();
    });
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
