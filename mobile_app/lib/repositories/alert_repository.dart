import '../models/alert_item.dart';

abstract class AlertRepository {
  /// Stream stream of active alerts
  Stream<List<AlertItem>> watchAlerts();

  /// Stream unread alerts count
  Stream<int> watchUnreadCount();

  /// Mark an alert as read
  Future<void> markAlertAsRead(String alertId);

  /// Mark all alerts as read
  Future<void> markAllAsRead();
}
