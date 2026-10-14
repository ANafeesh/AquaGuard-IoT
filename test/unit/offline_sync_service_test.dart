import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/core/services/offline_sync_service.dart';
import 'package:aquaguard/services/local_storage_service.dart';
import 'package:aquaguard/models/measurement.dart';

void main() {
  setUp(() async {
    await LocalStorageService.instance.init();
    await OfflineSyncService.instance.clearPendingQueue();
  });

  tearDown(() async {
    await OfflineSyncService.instance.clearPendingQueue();
    OfflineSyncService.instance.dispose();
  });

  group('OfflineSyncService Tests', () {
    test('Enqueuing a measurement increments pending count and marks as pending', () async {
      final now = DateTime.now();
      final measurement = Measurement(
        id: 'offline_m_1',
        sourceId: 'ws-1',
        ph: 7.2,
        tdsEc: 340.0,
        turbidity: 3.1,
        temperature: 27.5,
        latitude: 6.9271,
        longitude: 79.8612,
        timestamp: now,
        submittedBy: 'Test User',
        source: 'community',
      );

      await OfflineSyncService.instance.enqueueMeasurement(measurement);

      expect(OfflineSyncService.instance.pendingCount, 1);
      final pendingList = OfflineSyncService.instance.getPendingMeasurements();
      expect(pendingList.length, 1);
      expect(pendingList.first.id, 'offline_m_1');
      expect(pendingList.first.isPendingSync, isTrue);
    });

    test('Enqueueing identical ID updates existing item and prevents duplicate records', () async {
      final now = DateTime.now();
      final m1 = Measurement(
        id: 'dup_m_1',
        sourceId: 'ws-1',
        ph: 7.1,
        tdsEc: 300.0,
        turbidity: 2.5,
        temperature: 26.0,
        latitude: 6.9,
        longitude: 79.8,
        timestamp: now,
        submittedBy: 'Test User',
        source: 'community',
      );

      final m2 = m1.copyWith(ph: 7.4);

      await OfflineSyncService.instance.enqueueMeasurement(m1);
      await OfflineSyncService.instance.enqueueMeasurement(m2);

      // Should still be exactly 1 item in queue, updated with latest ph
      expect(OfflineSyncService.instance.pendingCount, 1);
      final pending = OfflineSyncService.instance.getPendingMeasurements();
      expect(pending.length, 1);
      expect(pending.first.ph, 7.4);
    });

    test('syncPending uploads pending items and removes them only on success', () async {
      final now = DateTime.now();
      final m1 = Measurement(
        id: 'sync_1',
        sourceId: 'ws-1',
        ph: 7.0,
        tdsEc: 250.0,
        turbidity: 2.0,
        temperature: 25.0,
        latitude: 6.9,
        longitude: 79.8,
        timestamp: now,
        submittedBy: 'User 1',
        source: 'community',
      );
      final m2 = Measurement(
        id: 'sync_2',
        sourceId: 'ws-1',
        ph: 7.5,
        tdsEc: 280.0,
        turbidity: 2.2,
        temperature: 26.0,
        latitude: 6.9,
        longitude: 79.8,
        timestamp: now,
        submittedBy: 'User 2',
        source: 'community',
      );

      await OfflineSyncService.instance.enqueueMeasurement(m1);
      await OfflineSyncService.instance.enqueueMeasurement(m2);
      expect(OfflineSyncService.instance.pendingCount, 2);

      // Simulate partial sync: sync_1 succeeds, sync_2 fails
      final syncedCount = await OfflineSyncService.instance.syncPending(
        uploadCallback: (item) async {
          if (item.id == 'sync_1') return true;
          return false;
        },
      );

      expect(syncedCount, 1);
      expect(OfflineSyncService.instance.pendingCount, 1);
      final remaining = OfflineSyncService.instance.getPendingMeasurements();
      expect(remaining.length, 1);
      expect(remaining.first.id, 'sync_2');
    });
  });
}
