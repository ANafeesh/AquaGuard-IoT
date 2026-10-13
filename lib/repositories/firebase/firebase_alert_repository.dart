import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../models/alert_item.dart';
import '../alert_repository.dart';

class FirebaseAlertRepository implements AlertRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection({bool isDemo = false}) =>
      _firestore.collection(AppConfig.getAlertsCollection(isDemo: isDemo));

  @override
  Stream<List<AlertItem>> watchAlerts({bool isDemo = false}) {
    return _collection(isDemo: isDemo)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return AlertItem.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<List<AlertItem>> getAlerts({bool isDemo = false}) async {
    try {
      final snapshot = await _collection(isDemo: isDemo)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return AlertItem.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<int> watchUnreadCount({bool isDemo = false}) {
    return _collection(isDemo: isDemo)
        .where('acknowledged', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Future<int> getUnacknowledgedCount({bool isDemo = false}) async {
    try {
      final snapshot = await _collection(isDemo: isDemo)
          .where('acknowledged', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> acknowledgeAlert(String alertId, {bool isDemo = false}) async {
    await _collection(isDemo: isDemo).doc(alertId).update({
      'acknowledged': true,
    });
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    await acknowledgeAlert(alertId, isDemo: false);
  }

  @override
  Future<void> markAllAsRead({bool isDemo = false}) async {
    final snapshot = await _collection(isDemo: isDemo)
        .where('acknowledged', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'acknowledged': true});
    }
    await batch.commit();
  }

  @override
  Future<void> createAlert(AlertItem alert, {bool isDemo = false}) async {
    await _collection(isDemo: isDemo).doc(alert.id).set(alert.toJson());
  }
}
