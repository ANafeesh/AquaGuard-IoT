import '../models/alert_item.dart';

abstract class AlertRepository {
  /// Stream stream of active anomaly alerts
  Stream<List<AlertItem>> watchAlerts({bool isDemo = false});

  /// Get list of all anomaly alerts
  Future<List<AlertItem>> getAlerts({bool isDemo = false});

  /// Stream unacknowledged alerts count for dashboard badges
  Stream<int> watchUnreadCount({bool isDemo = false});

  /// Get current unacknowledged count
  Future<int> getUnacknowledgedCount({bool isDemo = false});

  /// Acknowledge/mark an alert as read
  Future<void> acknowledgeAlert(String alertId, {bool isDemo = false});

  /// Legacy alias
  Future<void> markAlertAsRead(String alertId);

  /// Mark all alerts as acknowledged
  Future<void> markAllAsRead({bool isDemo = false});

  /// Record a new anomaly alert
  Future<void> createAlert(AlertItem alert, {bool isDemo = false});
}
