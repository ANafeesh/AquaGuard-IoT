import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaguard/screens/report_measurement_screen.dart';
import 'package:aquaguard/providers/app_state_providers.dart';
import 'package:aquaguard/providers/repository_providers.dart';
import 'package:aquaguard/repositories/auth_repository.dart';
import 'package:aquaguard/repositories/mock/mock_auth_repository.dart';
import 'package:aquaguard/repositories/mock/mock_report_repository.dart';
import 'package:aquaguard/repositories/mock/mock_reading_repository.dart';
import 'package:aquaguard/models/water_source.dart';
import 'package:aquaguard/core/services/offline_sync_service.dart';

void main() {
  tearDown(() {
    OfflineSyncService.instance.dispose();
  });
  Widget createReportWidget({
    AppUser? user,
    MockReportRepository? mockReportRepo,
    MockReadingRepository? mockReadingRepo,
    MockAuthRepository? mockAuthRepo,
  }) {
    final defaultUser = user ??
        const AppUser(
          id: 'user_123',
          email: 'citizen@aquaguard.org',
          displayName: 'Jane Doe',
          isGuest: false,
        );

    final authRepo = mockAuthRepo ?? MockAuthRepository();
    authRepo.setCurrentUser(defaultUser);

    final mockSources = [
      WaterSource(
        id: 'ws-1',
        name: 'Lake View Point',
        type: WaterSourceType.lake,
        latitude: 6.9271,
        longitude: 79.8612,
        createdBy: 'admin',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        lastReadingAt: DateTime.now(),
      ),
    ];

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        currentUserProvider.overrideWith((ref) => Stream.value(defaultUser)),
        waterSourcesStreamProvider.overrideWith((ref) => Stream.value(mockSources)),
        if (mockReportRepo != null)
          reportRepositoryProvider.overrideWithValue(mockReportRepo),
        if (mockReadingRepo != null)
          readingRepositoryProvider.overrideWithValue(mockReadingRepo),
      ],
      child: const MaterialApp(
        home: ReportMeasurementScreen(),
      ),
    );
  }

  testWidgets('ReportMeasurementScreen renders disclaimer banner, parameters, and inputs', (WidgetTester tester) async {
    await tester.pumpWidget(createReportWidget());
    await tester.pumpAndSettle();

    // Verify Title & Disclaimer
    expect(find.text('Community Water Observation'), findsOneWidget);
    expect(find.textContaining('does not certify whether water is safe to drink'), findsOneWidget);

    // Verify Source Selection
    expect(find.text('Existing Monitored Source'), findsOneWidget);
    expect(find.text('New Water Source'), findsOneWidget);

    // Verify Parameter Inputs
    expect(find.textContaining('pH Level'), findsOneWidget);
    expect(find.textContaining('TDS / EC'), findsOneWidget);
    expect(find.textContaining('Turbidity'), findsOneWidget);
    expect(find.textContaining('Temperature'), findsOneWidget);

    // Verify Submit Button
    expect(find.byKey(const Key('submit_observation_button')), findsOneWidget);
  });

  testWidgets('ReportMeasurementScreen displays validation error when no parameters are entered', (WidgetTester tester) async {
    await tester.pumpWidget(createReportWidget());
    await tester.pumpAndSettle();

    // Tap submit without entering any parameters
    final submitButton = find.byKey(const Key('submit_observation_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify validation failure error banner
    expect(find.textContaining('At least one water-quality parameter'), findsOneWidget);
  });

  testWidgets('Guest user is blocked from submitting community readings with dialog', (WidgetTester tester) async {
    final guestUser = AppUser.guest();

    await tester.pumpWidget(createReportWidget(user: guestUser));
    await tester.pumpAndSettle();

    // Enter a valid pH value
    final phField = find.byKey(const Key('ph_input_field'));
    await tester.enterText(phField, '7.4');
    await tester.pump();

    // Attempt submission
    final submitButton = find.byKey(const Key('submit_observation_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify Guest blocking dialog appears
    expect(find.text('Account Required'), findsOneWidget);
    expect(find.textContaining('Guest mode allows viewing community data and map indicators'), findsOneWidget);
    expect(find.text('Sign In Now'), findsOneWidget);
  });

  testWidgets('Authenticated user successfully submits valid reading', (WidgetTester tester) async {
    final mockReportRepo = MockReportRepository();
    final mockReadingRepo = MockReadingRepository();

    await tester.pumpWidget(createReportWidget(
      mockReportRepo: mockReportRepo,
      mockReadingRepo: mockReadingRepo,
    ));
    await tester.pumpAndSettle();

    // Enter valid pH value
    final phField = find.byKey(const Key('ph_input_field'));
    await tester.enterText(phField, '7.35');
    await tester.pump();

    // Tap submit
    final submitButton = find.byKey(const Key('submit_observation_button'));
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify observation was submitted to repository
    final observations = await mockReportRepo.watchObservations().first;
    expect(observations.isNotEmpty, isTrue);
    expect(observations.first.ph, 7.35);
  });

  testWidgets('ReportMeasurementScreen provides Select on Map and Choose City buttons', (WidgetTester tester) async {
    await tester.pumpWidget(createReportWidget());
    await tester.pumpAndSettle();

    expect(find.text('Select on Map'), findsOneWidget);
    expect(find.text('Choose City'), findsOneWidget);
    expect(find.text('Use GPS'), findsOneWidget);
  });

  testWidgets('Selecting New Water Source and typing Kandy auto-detects Kandy coordinates', (WidgetTester tester) async {
    await tester.pumpWidget(createReportWidget());
    await tester.pumpAndSettle();

    // Select New Water Source
    final newSourceChip = find.text('New Water Source');
    await tester.tap(newSourceChip);
    await tester.pumpAndSettle();

    // Type "Kandy" in new source name field
    final sourceNameField = find.widgetWithText(TextFormField, 'New Water Source Name');
    expect(sourceNameField, findsOneWidget);
    await tester.enterText(sourceNameField, 'Kandy Lake');
    await tester.pumpAndSettle();

    // Verify auto-detected Kandy coordinates appear
    expect(find.textContaining('7.2906° N, 80.6337° E'), findsOneWidget);
    expect(find.textContaining('Matched: Kandy'), findsOneWidget);
  });
}
