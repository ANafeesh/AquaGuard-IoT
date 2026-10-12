import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/measurement.dart';
import '../../services/local_storage_service.dart';

/// Manages offline state detection, local caching, and synchronization
/// of queued community readings with client-generated UUIDs.
class OfflineSyncService {
  static const String _pendingQueueKey = 'pending_offline_measurements';
  static OfflineSyncService? _instance;
  static OfflineSyncService get instance => _instance ??= OfflineSyncService._();

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<int> pendingCountNotifier = ValueNotifier<int>(0);

  Timer? _connectivityPollTimer;
  bool _isSyncing = false;

  OfflineSyncService._() {
    _init();
  }

  void _init() {
    _updatePendingCount();
    // Initial connectivity check
    checkConnectivity();
    // Periodic liveness check every 15 seconds
    _connectivityPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      checkConnectivity();
    });
  }

  void dispose() {
    _connectivityPollTimer?.cancel();
  }

  bool get isOnline => isOnlineNotifier.value;
  int get pendingCount => pendingCountNotifier.value;

  /// Check network availability without requiring native platform FFI symlinks
  Future<bool> checkConnectivity() async {
    if (kIsWeb) {
      isOnlineNotifier.value = true;
      return true;
    }

    try {
      final lookup = await InternetAddress.lookup('dns.google').timeout(
        const Duration(seconds: 4),
        onTimeout: () => [],
      );
      final connected = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      if (isOnlineNotifier.value != connected) {
        isOnlineNotifier.value = connected;
      }
      return connected;
    } catch (_) {
      // In offline / local mock environment
      // If error occurs, flag offline
      if (isOnlineNotifier.value != false) {
        isOnlineNotifier.value = false;
      }
      return false;
    }
  }

  void setOnlineOverride(bool online) {
    isOnlineNotifier.value = online;
  }

  /// Retrieves list of pending measurements stored in local storage
  List<Measurement> getPendingMeasurements() {
    final list = LocalStorageService.instance.getJsonList(_pendingQueueKey);
    return list.map((m) => Measurement.fromJson(m).copyWith(isPendingSync: true)).toList();
  }

  /// Adds a measurement to the local offline queue
  Future<void> enqueueMeasurement(Measurement measurement) async {
    final current = LocalStorageService.instance.getJsonList(_pendingQueueKey);
    // Ensure no duplicates by ID
    current.removeWhere((item) => item['id'] == measurement.id);
    current.add(measurement.copyWith(isPendingSync: true).toJson());
    await LocalStorageService.instance.setJsonList(_pendingQueueKey, current);
    _updatePendingCount();
  }

  /// Removes a measurement from the queue after successful upload
  Future<void> removePendingMeasurement(String id) async {
    final current = LocalStorageService.instance.getJsonList(_pendingQueueKey);
    current.removeWhere((item) => item['id'] == id);
    await LocalStorageService.instance.setJsonList(_pendingQueueKey, current);
    _updatePendingCount();
  }

  /// Clears the queue
  Future<void> clearPendingQueue() async {
    await LocalStorageService.instance.remove(_pendingQueueKey);
    _updatePendingCount();
  }

  void _updatePendingCount() {
    final list = LocalStorageService.instance.getJsonList(_pendingQueueKey);
    pendingCountNotifier.value = list.length;
  }

  /// Synchronizes all pending measurements using the provided upload handler callback
  Future<int> syncPending({
    required Future<bool> Function(Measurement) uploadCallback,
  }) async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    int syncedCount = 0;

    try {
      final pending = getPendingMeasurements();
      for (final measurement in pending) {
        try {
          final success = await uploadCallback(measurement);
          if (success) {
            await removePendingMeasurement(measurement.id);
            syncedCount++;
          }
        } catch (e) {
          debugPrint('Failed to sync item ${measurement.id}: $e');
        }
      }
    } finally {
      _isSyncing = false;
      _updatePendingCount();
    }

    return syncedCount;
  }
}
