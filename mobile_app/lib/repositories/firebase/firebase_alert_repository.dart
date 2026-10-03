import '../../models/alert_item.dart';
import '../alert_repository.dart';

class FirebaseAlertRepository implements AlertRepository {
  @override
  Stream<List<AlertItem>> watchAlerts() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Stream<int> watchUnreadCount() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> markAlertAsRead(String alertId) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> markAllAsRead() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }
}
