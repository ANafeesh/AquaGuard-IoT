import 'dart:async';
import '../../models/alert_item.dart';
import '../../data/mock_data.dart';
import '../../services/local_storage_service.dart';
import '../alert_repository.dart';

class MockAlertRepository implements AlertRepository {
  static const String _storageKey = 'aquaguard_alerts';
  final _alertsController = StreamController<List<AlertItem>>.broadcast();
  final List<AlertItem> _localAlerts = [];

  MockAlertRepository() {
    _loadAlerts();
  }

  void _loadAlerts() {
    final cached = LocalStorageService.instance.getJsonList(_storageKey);
    if (cached.isNotEmpty) {
      _localAlerts.addAll(cached.map((j) => AlertItem.fromJson(j)));
    } else {
      _localAlerts.addAll(MockData.alerts);
    }
    _alertsController.add(_localAlerts);
  }

  Future<void> _persist() async {
    await LocalStorageService.instance.setJsonList(
      _storageKey,
      _localAlerts.map((a) => a.toJson()).toList(),
    );
  }

  @override
  Stream<List<AlertItem>> watchAlerts() async* {
    yield _localAlerts;
    yield* _alertsController.stream;
  }

  @override
  Stream<int> watchUnreadCount() async* {
    yield _localAlerts.where((a) => !a.isRead).length;
    yield* _alertsController.stream.map(
      (list) => list.where((a) => !a.isRead).length,
    );
  }

  @override
  Future<void> markAlertAsRead(String alertId) async {
    final idx = _localAlerts.indexWhere((a) => a.id == alertId);
    if (idx != -1 && !_localAlerts[idx].isRead) {
      _localAlerts[idx] = _localAlerts[idx].copyWith(isRead: true);
      _alertsController.add(List.unmodifiable(_localAlerts));
      await _persist();
    }
  }

  @override
  Future<void> markAllAsRead() async {
    bool changed = false;
    for (int i = 0; i < _localAlerts.length; i++) {
      if (!_localAlerts[i].isRead) {
        _localAlerts[i] = _localAlerts[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _alertsController.add(List.unmodifiable(_localAlerts));
      await _persist();
    }
  }
}
