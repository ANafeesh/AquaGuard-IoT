import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/constants/parameter_thresholds.dart';
import 'package:aquaguard/models/water_source.dart';
import 'package:aquaguard/models/measurement.dart';
import 'package:aquaguard/models/community_observation.dart';
import 'package:aquaguard/repositories/mock/mock_water_source_repository.dart';
import 'package:aquaguard/repositories/mock/mock_reading_repository.dart';
import 'package:aquaguard/repositories/mock/mock_alert_repository.dart';
import 'package:aquaguard/repositories/mock/mock_report_repository.dart';
import 'package:aquaguard/repositories/mock/mock_auth_repository.dart';

void main() {
  group('Phase A: ParameterThresholds Tests', () {
    test('pH threshold evaluation', () {
      expect(ParameterThresholds.isPhTypical(7.2), isTrue);
      expect(ParameterThresholds.isPhTypical(6.5), isTrue);
      expect(ParameterThresholds.isPhTypical(8.5), isTrue);
      expect(ParameterThresholds.isPhTypical(6.0), isFalse);
      expect(ParameterThresholds.isPhTypical(9.0), isFalse);
    });

    test('TDS threshold evaluation', () {
      expect(ParameterThresholds.isTdsTypical(320), isTrue);
      expect(ParameterThresholds.isTdsTypical(150), isTrue);
      expect(ParameterThresholds.isTdsTypical(500), isTrue);
      expect(ParameterThresholds.isTdsTypical(120), isFalse);
      expect(ParameterThresholds.isTdsTypical(650), isFalse);
    });

    test('Turbidity threshold evaluation', () {
      expect(ParameterThresholds.isTurbidityTypical(3.4), isTrue);
      expect(ParameterThresholds.isTurbidityTypical(0.5), isTrue);
      expect(ParameterThresholds.isTurbidityTypical(5.0), isTrue);
      expect(ParameterThresholds.isTurbidityTypical(7.5), isFalse);
    });

    test('Temperature threshold evaluation', () {
      expect(ParameterThresholds.isTempTypical(28.4), isTrue);
      expect(ParameterThresholds.isTempTypical(18.0), isFalse);
      expect(ParameterThresholds.isTempTypical(35.0), isFalse);
    });
  });

  group('Phase A: WaterQualityStatus Labels Tests', () {
    test('Strict status terminology adherence', () {
      expect(WaterQualityStatus.withinTypicalRange.label, 'Within typical range');
      expect(WaterQualityStatus.unusual.label, 'Unusual');
      expect(WaterQualityStatus.noRecentData.label, 'No recent data');

      // Ensure no potable declarations
      for (final status in WaterQualityStatus.values) {
        expect(status.label.toLowerCase().contains('safe'), isFalse);
        expect(status.label.toLowerCase().contains('drink'), isFalse);
      }
    });
  });

  group('Phase A: Repository Layer Tests', () {
    test('MockWaterSourceRepository retrieves and switches sources', () async {
      final repo = MockWaterSourceRepository();
      final sources = await repo.watchWaterSources().first;
      expect(sources.isNotEmpty, isTrue);
      expect(sources.first.name, 'Lake View Point');

      final active = await repo.getActiveWaterSource();
      expect(active.id, 'ws-1');

      await repo.setActiveWaterSourceId('ws-2');
      final newActive = await repo.getActiveWaterSource();
      expect(newActive.id, 'ws-2');
      expect(newActive.name, 'Riverside');
    });

    test('MockReadingRepository streams readings and trends', () async {
      final repo = MockReadingRepository();
      final readings = await repo.watchLatestReadings('ws-1').first;
      expect(readings.length, 4);

      final phReading = readings.firstWhere((r) => r.type == ParameterType.ph);
      expect(phReading.value, 7.2);
      expect(phReading.status, WaterQualityStatus.withinTypicalRange);

      final trends = await repo.getHistoricalTrends('ws-1', ParameterType.ph);
      expect(trends.containsKey('24H'), isTrue);
      expect(trends['24H']!.isNotEmpty, isTrue);
    });

    test('MockAlertRepository updates unread counts', () async {
      final repo = MockAlertRepository();
      final alerts = await repo.watchAlerts().first;
      expect(alerts.isNotEmpty, isTrue);

      final initialUnread = await repo.watchUnreadCount().first;
      expect(initialUnread, greaterThan(0));

      await repo.markAllAsRead();
      final updatedUnread = await repo.watchUnreadCount().first;
      expect(updatedUnread, 0);
    });

    test('MockReportRepository queues submitted observation', () async {
      final repo = MockReportRepository();
      final initialCount = (await repo.watchObservations().first).length;

      const newObs = CommunityObservation(
        id: 'obs-test',
        waterSourceName: 'Lake View Point',
        locationArea: 'Test Area',
        userName: 'Tester',
        userAvatar: 'T',
        timeAgo: 'Just now',
        notes: 'Testing observation submit',
        status: WaterQualityStatus.withinTypicalRange,
      );

      await repo.submitObservation(newObs);
      final updated = await repo.watchObservations().first;
      expect(updated.length, initialCount + 1);
      expect(updated.first.id, 'obs-test');
    });

    test('MockAuthRepository handles auth lifecycle and initials', () async {
      final repo = MockAuthRepository();
      final user = await repo.signIn('john.doe@example.com', 'secret123');
      expect(user.email, 'john.doe@example.com');
      expect(user.initials, 'J');

      await repo.signOut();
      expect(repo.getCurrentUser(), isNull);
    });

    test('MockReadingRepository logs and dynamic delta calculations', () async {
      final repo = MockReadingRepository();
      final initialLogs = await repo.watchReadingLogs('ws-1').first;
      expect(initialLogs.isNotEmpty, isTrue);

      final delta = await repo.getReadingDelta('ws-1', ParameterType.ph);
      expect(delta.containsKey('latest'), isTrue);
      expect(delta.containsKey('previous'), isTrue);
      expect(delta.containsKey('change'), isTrue);
    });

    test('MockReportRepository upvoting, deleting, and updating notes', () async {
      final repo = MockReportRepository();
      final obsList = await repo.watchObservations().first;
      final target = obsList.first;

      final initialHelpful = target.helpfulCount;
      await repo.upvoteObservation(target.id);
      final updatedList = await repo.watchObservations().first;
      expect(updatedList.firstWhere((o) => o.id == target.id).helpfulCount, initialHelpful + 1);

      await repo.updateObservationNote(target.id, 'Updated note for test verification');
      final updatedNoteList = await repo.watchObservations().first;
      expect(updatedNoteList.firstWhere((o) => o.id == target.id).notes, 'Updated note for test verification');

      await repo.deleteObservation(target.id);
      final afterDeleteList = await repo.watchObservations().first;
      expect(afterDeleteList.any((o) => o.id == target.id), isFalse);
    });
  });
}
