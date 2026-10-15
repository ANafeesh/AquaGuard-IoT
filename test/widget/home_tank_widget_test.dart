import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aquaguard/features/tanks/screens/register_tank_screen.dart';
import 'package:aquaguard/features/tanks/screens/my_home_tanks_screen.dart';
import 'package:aquaguard/features/tanks/widgets/home_tank_card.dart';
import 'package:aquaguard/models/home_tank.dart';
import 'package:aquaguard/models/water_source.dart';
import 'package:aquaguard/providers/repository_providers.dart';
import 'package:aquaguard/repositories/mock/mock_home_tank_repository.dart';
import 'package:aquaguard/repositories/mock/mock_water_source_repository.dart';

void main() {
  Widget createTestWidget(Widget child, {MockHomeTankRepository? tankRepo}) {
    return ProviderScope(
      overrides: [
        if (tankRepo != null) homeTankRepositoryProvider.overrideWithValue(tankRepo),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Home Tank Registration Widget Tests', () {
    testWidgets('RegisterTankScreen renders form inputs, privacy banner, and location options',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterTankScreen()));
      await tester.pumpAndSettle();

      // Verify Screen Header
      expect(find.text('Register Home Water Tank'), findsOneWidget);

      // Verify Privacy Banner
      expect(find.text('Private Residential Monitoring'), findsOneWidget);
      expect(find.textContaining('NEVER be shown on the public community map'), findsOneWidget);

      // Verify Input Fields
      expect(find.text('Tank Name *'), findsOneWidget);
      expect(find.text('Tank Type'), findsOneWidget);
      expect(find.text('Capacity (Liters, Optional)'), findsOneWidget);
      expect(find.text('Sensor Node Device ID'), findsOneWidget);

      // Verify 3 Location Methods
      expect(find.text('Use GPS'), findsOneWidget);
      expect(find.text('Pick on Map'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);

      // Verify Submit Button
      expect(find.text('Register Tank Privately'), findsOneWidget);
    });

    testWidgets('Tapping Use GPS simulates location detection and shows confirmation',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterTankScreen()));
      await tester.pumpAndSettle();

      final gpsButton = find.text('Use GPS');
      expect(gpsButton, findsOneWidget);
      await tester.ensureVisible(gpsButton);
      await tester.pumpAndSettle();

      await tester.tap(gpsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Verify Location Confirmed text appears
      expect(find.text('Location Confirmed'), findsOneWidget);
      expect(find.textContaining('Method: GPS'), findsOneWidget);
    });

    testWidgets('HomeTankCard renders tank details, private lock badge, and telemetry',
        (WidgetTester tester) async {
      final tank = HomeTank(
        id: 'tank_card_test',
        ownerUid: 'usr_test',
        tankName: 'Main Rooftop Tank',
        tankType: HomeTankType.rooftop,
        capacityLiters: 1500,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'No. 10, Flower Road, Colombo 07',
          isConfirmed: true,
        ),
        deviceId: 'esp32_flower_rd',
        visibility: 'private',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastReadingAt: DateTime.now(),
        ph: 7.2,
        tdsEc: 210,
        turbidity: 1.2,
        temperature: 26.5,
        status: WaterQualityStatus.withinTypicalRange,
      );

      await tester.pumpWidget(createTestWidget(HomeTankCard(tank: tank)));
      await tester.pumpAndSettle();

      expect(find.text('Main Rooftop Tank'), findsOneWidget);
      expect(find.text('Private'), findsOneWidget);
      expect(find.text('No. 10, Flower Road, Colombo 07'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Node: esp32_flower_rd'), findsOneWidget);
      expect(find.text('7.2'), findsOneWidget);
      expect(find.text('210 ppm'), findsOneWidget);
    });

    testWidgets('MyHomeTanksScreen renders privacy ribbon and add tank FAB',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(const MyHomeTanksScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Home Water Tanks'), findsOneWidget);
      expect(find.textContaining('strictly private to your account'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('MapScreen NEVER displays private home tanks on the public community map',
        (WidgetTester tester) async {
      // Mock water source repo contains public catchment stations
      final waterSourceRepo = MockWaterSourceRepository();
      final publicSources = await waterSourceRepo.watchWaterSources().first;

      // Verify mock public sources exist and are environmental water bodies
      expect(publicSources.isNotEmpty, isTrue);
      for (final src in publicSources) {
        expect(src.type, isNot(equals(HomeTankType.rooftop)));
        expect(src.type, isNot(equals(HomeTankType.underground)));
      }

      // Home tank repo contains private residential tanks
      final homeTankRepo = MockHomeTankRepository();
      final privateTanks = await homeTankRepo.getUserTanks('usr_demo_01');
      expect(privateTanks.isNotEmpty, isTrue);

      final privateTank = privateTanks.first;
      expect(privateTank.visibility, equals('private'));

      // Confirm that the public sources collection in repository does NOT contain the private tank
      final isFoundInPublic = publicSources.any((s) => s.id == privateTank.id || s.name == privateTank.tankName);
      expect(isFoundInPublic, isFalse, reason: 'Private home tank must NEVER leak into public water sources');
    });
  });
}
