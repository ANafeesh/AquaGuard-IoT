import 'package:flutter_test/flutter_test.dart';
import 'package:aquaguard/models/home_tank.dart';
import 'package:aquaguard/models/tank_reading.dart';
import 'package:aquaguard/models/water_source.dart';
import 'package:aquaguard/repositories/mock/mock_home_tank_repository.dart';

void main() {
  group('HomeTank Model & Privacy Tests', () {
    test('HomeTank initializes with private visibility and correct types', () {
      final now = DateTime.now();
      final tank = HomeTank(
        id: 'tank_test_01',
        ownerUid: 'user_alice',
        tankName: 'Alice Rooftop Tank',
        tankType: HomeTankType.rooftop,
        capacityLiters: 1000,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: '42 Galle Road, Colombo',
          locationMethod: 'gps',
          isConfirmed: true,
        ),
        deviceId: 'esp32_alice_node',
        visibility: 'private',
        createdAt: now,
        updatedAt: now,
        ph: 7.2,
        tdsEc: 220,
        turbidity: 1.1,
        temperature: 26.5,
        status: WaterQualityStatus.withinTypicalRange,
      );

      expect(tank.visibility, equals('private'));
      expect(tank.hasDevice, isTrue);
      expect(tank.location.isConfirmed, isTrue);
      expect(tank.location.formattedCoordinates, contains('6.9271° N, 79.8612° E'));

      // Test JSON round-trip
      final json = tank.toJson();
      expect(json['visibility'], equals('private'));
      expect(json['ownerUid'], equals('user_alice'));
      expect(json['tankType'], equals('rooftop'));

      final parsed = HomeTank.fromJson(json);
      expect(parsed.id, equals(tank.id));
      expect(parsed.ownerUid, equals(tank.ownerUid));
      expect(parsed.visibility, equals('private'));
      expect(parsed.tankType, equals(HomeTankType.rooftop));
      expect(parsed.location.address, equals('42 Galle Road, Colombo'));
    });

    test('HomeTankType extension covers all tank classifications', () {
      expect(HomeTankType.rooftop.displayName, contains('Rooftop'));
      expect(HomeTankType.underground.displayName, contains('Underground'));
      expect(HomeTankType.rainwater.displayName, contains('Rainwater'));
      expect(HomeTankType.indoor.displayName, contains('Indoor'));
      expect(HomeTankType.other.displayName, contains('Other'));

      expect(HomeTankTypeExtension.fromString('rooftop'), equals(HomeTankType.rooftop));
      expect(HomeTankTypeExtension.fromString('underground'), equals(HomeTankType.underground));
      expect(HomeTankTypeExtension.fromString('unknown_val'), equals(HomeTankType.rooftop));
    });
  });

  group('Two-User Privacy & Owner-Only Access Tests', () {
    late MockHomeTankRepository repo;

    setUp(() {
      repo = MockHomeTankRepository();
    });

    test('User A registers tank -> User B CANNOT view, list, or access it', () async {
      const userA = 'user_A_id_123';
      const userB = 'user_B_id_456';

      final tankA = HomeTank(
        id: 'tank_user_a',
        ownerUid: userA,
        tankName: 'User A Private Rooftop',
        tankType: HomeTankType.rooftop,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'Secret Private Home Address of User A',
          isConfirmed: true,
        ),
        deviceId: 'esp32_device_user_a',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // User A registers their tank
      await repo.registerTank(tankA);

      // User A queries their tanks
      final userATanks = await repo.getUserTanks(userA);
      expect(userATanks.any((t) => t.id == 'tank_user_a'), isTrue);

      // User B queries their tanks
      final userBTanks = await repo.getUserTanks(userB);
      expect(userBTanks.any((t) => t.id == 'tank_user_a'), isFalse);
      expect(userBTanks.any((t) => t.location.address.contains('User A')), isFalse);

      // Verify stream scoping for User B
      final streamResult = await repo.watchUserTanks(userB).first;
      expect(streamResult.any((t) => t.id == 'tank_user_a'), isFalse);
    });

    test('User B CANNOT modify or hijack User A tank ownership', () async {
      const userA = 'user_A_id_123';
      const userB = 'user_B_id_456';

      final tankA = HomeTank(
        id: 'tank_protected_01',
        ownerUid: userA,
        tankName: 'Original Tank Name',
        tankType: HomeTankType.rooftop,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'User A Home',
          isConfirmed: true,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.registerTank(tankA);

      // Malicious attempt by User B to update User A's tank or change ownerUid
      final hijackedTank = tankA.copyWith(
        ownerUid: userB,
        tankName: 'Hijacked by User B',
      );

      expect(
        () async => await repo.updateTank(hijackedTank),
        throwsA(isA<Exception>()),
      );

      // Verify original tank remains intact and owned by User A
      final intact = await repo.getTankById('tank_protected_01');
      expect(intact?.ownerUid, equals(userA));
      expect(intact?.tankName, equals('Original Tank Name'));
    });

    test('Device conflict prevention: User B cannot register device claimed by User A', () async {
      const userA = 'user_A_id_123';
      const userB = 'user_B_id_456';
      const deviceId = 'esp32_exclusive_node_01';

      final tankA = HomeTank(
        id: 'tank_a_device',
        ownerUid: userA,
        tankName: 'Tank A Node',
        tankType: HomeTankType.rooftop,
        deviceId: deviceId,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'User A Home',
          isConfirmed: true,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.registerTank(tankA);

      // User A check is available for User A
      final availableForA = await repo.verifyDeviceAvailability(deviceId, userA);
      expect(availableForA, isTrue);

      // User B check MUST be false (already claimed by User A)
      final availableForB = await repo.verifyDeviceAvailability(deviceId, userB);
      expect(availableForB, isFalse);

      // User B attempting to register a tank with User A's device throws Exception
      final tankB = HomeTank(
        id: 'tank_b_hijack',
        ownerUid: userB,
        tankName: 'Tank B Impersonator',
        tankType: HomeTankType.rooftop,
        deviceId: deviceId,
        location: const HomeTankInstallationLocation(
          latitude: 6.9100,
          longitude: 79.8600,
          address: 'User B Home',
          isConfirmed: true,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () async => await repo.registerTank(tankB),
        throwsA(isA<Exception>()),
      );
    });

    test('User A can edit and delete their own tank, and deletion safely purges subcollection readings', () async {
      const userA = 'user_A_id_123';
      final tankA = HomeTank(
        id: 'tank_a_cascade',
        ownerUid: userA,
        tankName: 'Tank To Edit and Delete',
        tankType: HomeTankType.rooftop,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'User A Home',
          isConfirmed: true,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.registerTank(tankA);

      // Add readings
      final reading = TankReading(
        id: 'reading_cascade_1',
        tankId: tankA.id,
        ownerUid: userA,
        ph: 7.4,
        tdsEc: 210,
        turbidity: 1.0,
        temperature: 25.5,
        timestamp: DateTime.now(),
      );
      await repo.addTankReading(reading);

      // Verify reading exists
      final readingsBefore = await repo.watchTankReadings(tankA.id).first;
      expect(readingsBefore.length, equals(1));

      // User A edits tank
      final updated = tankA.copyWith(tankName: 'Tank Successfully Renamed');
      await repo.updateTank(updated);
      final fetched = await repo.getTankById(tankA.id);
      expect(fetched?.tankName, equals('Tank Successfully Renamed'));

      // User A deletes tank
      await repo.deleteTank(tankA.id);

      // Verify tank is deleted
      final afterDelete = await repo.getTankById(tankA.id);
      expect(afterDelete, isNull);

      // Verify subcollection readings are also purged
      final readingsAfter = await repo.watchTankReadings(tankA.id).first;
      expect(readingsAfter.isEmpty, isTrue);
    });

    test('Failed deletion operations throw and are reported accurately', () async {
      repo.simulateDeletionFailure = true;

      expect(
        () async => await repo.deleteTank('any_tank_id'),
        throwsA(predicate((e) => e.toString().contains('Simulated database network error'))),
      );

      repo.simulateDeletionFailure = false;
    });

    test('Offline & No-Data States: Tank without readings reflects noRecentData status', () {
      final unmonitoredTank = HomeTank(
        id: 'tank_offline_01',
        ownerUid: 'user_c',
        tankName: 'New Tank Without Readings',
        tankType: HomeTankType.underground,
        location: const HomeTankInstallationLocation(
          latitude: 6.9271,
          longitude: 79.8612,
          address: 'Manual Entry Location',
          locationMethod: 'manual',
          isConfirmed: true,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(unmonitoredTank.status, equals(WaterQualityStatus.noRecentData));
      expect(unmonitoredTank.lastReadingAt, isNull);
      expect(unmonitoredTank.lastUpdatedFormatted, equals('No readings yet'));
    });
  });
}
