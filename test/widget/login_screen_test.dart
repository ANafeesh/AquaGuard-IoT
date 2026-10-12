import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaguard/screens/auth/login_screen.dart';
import 'package:aquaguard/screens/map_screen.dart';
import 'package:aquaguard/providers/repository_providers.dart';
import 'package:aquaguard/repositories/mock/mock_auth_repository.dart';
import 'package:aquaguard/core/services/offline_sync_service.dart';

void main() {
  setUp(() {
    MapScreen.defaultUseOpenStreetMap = false;
  });

  tearDown(() {
    MapScreen.defaultUseOpenStreetMap = true;
    OfflineSyncService.instance.dispose();
  });

  Widget createLoginWidget({MockAuthRepository? mockAuthRepo}) {
    return ProviderScope(
      overrides: [
        if (mockAuthRepo != null)
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  testWidgets('LoginScreen renders branding, email, password, and action buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createLoginWidget());
    await tester.pumpAndSettle();

    // Verify Title & Subtitle branding
    expect(find.text('Welcome to AquaGuard'), findsOneWidget);
    expect(find.text('Smart Water Quality & Community Monitoring'), findsOneWidget);

    // Verify Input Field Labels
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Verify Action Buttons
    expect(find.byKey(const Key('login_button')), findsOneWidget);
    expect(find.byKey(const Key('continue_as_guest_button')), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('LoginScreen validates invalid email and empty inputs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createLoginWidget());
    await tester.pumpAndSettle();

    // Clear pre-filled text in email field
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, 'not-an-email');
    await tester.pump();

    // Attempt Sign In
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Expect email validation error
    expect(find.text('Please enter a valid email'), findsOneWidget);
  });

  testWidgets('LoginScreen validates short password', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createLoginWidget());
    await tester.pumpAndSettle();

    // Enter short password (< 6 chars)
    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, '123');
    await tester.pump();

    // Attempt Sign In
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Expect password length validation error
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
  });

  testWidgets('Tapping Continue as Guest triggers guest authentication flow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockAuthRepository();

    await tester.pumpWidget(createLoginWidget(mockAuthRepo: mockRepo));
    await tester.pumpAndSettle();

    final guestButton = find.byKey(const Key('continue_as_guest_button'));
    expect(guestButton, findsOneWidget);

    await tester.tap(guestButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify guest user was created in repository
    final user = mockRepo.getCurrentUser();
    expect(user, isNotNull);
    expect(user!.isGuest, isTrue);
  });
}
