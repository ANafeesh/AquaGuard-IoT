import '../../models/alert_item.dart';
import '../alert_repository.dart';

class FirebaseAlertRepository implements AlertRepository {
  @override
  Stream<List<AlertItem>> watchAlerts({bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Future<List<AlertItem>> getAlerts({bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Stream<int> watchUnreadCount({bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Future<int> getUnacknowledgedCount({bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Future<void> acknowledgeAlert(String alertId, {bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Future<void> markAlertAsRead(String alertId) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Future<void> markAllAsRead({bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }

  @override
  Future<void> createAlert(AlertItem alert, {bool isDemo = false}) {
    throw UnimplementedError('Firebase backend configuration requires active cloud credentials.');
  }
}
