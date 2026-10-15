import 'dart:async';
import '../../models/home_tank.dart';
import '../../models/tank_reading.dart';
import '../../models/water_source.dart';
import '../home_tank_repository.dart';

/// In-memory mock repository for Home Tanks used in unit tests and demo mode.
/// Simulates private owner-only data access without any network dependency.
class MockHomeTankRepository implements HomeTankRepository {
  final List<HomeTank> _tanks = [];
  final Map<String, List<TankReading>> _readings = {};
  final StreamController<List<HomeTank>> _tanksStreamController =
      StreamController<List<HomeTank>>.broadcast();

  MockHomeTankRepository() {
    _initDefaultMockData();
  }

  void _initDefaultMockData() {
    final now = DateTime.now();
    final defaultTank = HomeTank(
      id: 'demo_tank_01',
      ownerUid: 'usr_demo_01',
      tankName: 'My Home Rooftop Tank',
      tankType: HomeTankType.rooftop,
      capacityLiters: 1000,
      location: const HomeTankInstallationLocation(
        latitude: 6.9147,
        longitude: 79.8732,
        address: 'No. 24, Havelock Road, Colombo 05',
        city: 'Colombo',
        locationMethod: 'gps',
        isConfirmed: true,
      ),
      deviceId: 'esp32_tank_node_01',
      visibility: 'private',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(minutes: 5)),
      lastReadingAt: now.subtract(const Duration(minutes: 8)),
      isActive: true,
      ph: 7.15,
      tdsEc: 210.0,
      turbidity: 1.2,
      temperature: 26.8,
      status: WaterQualityStatus.withinTypicalRange,
      notes: 'Residential overhead overhead tank. Cleaned 2 weeks ago.',
    );

    _tanks.add(defaultTank);

    // Initial mock readings for 7 days
    final tankReadings = <TankReading>[];
    for (int i = 0; i < 14; i++) {
      final time = now.subtract(Duration(hours: i * 4));
      tankReadings.add(
        TankReading(
          id: 'mock_tr_$i',
          tankId: defaultTank.id,
          ownerUid: defaultTank.ownerUid,
          deviceId: defaultTank.deviceId,
          ph: 7.0 + (i % 3) * 0.1,
          tdsEc: 200.0 + (i % 5) * 8.0,
          turbidity: 1.0 + (i % 4) * 0.2,
          temperature: 26.0 + (i % 3) * 0.5,
          timestamp: time,
          source: 'device',
          status: WaterQualityStatus.withinTypicalRange,
        ),
      );
    }
    _readings[defaultTank.id] = tankReadings;
  }

  @override
  Stream<List<HomeTank>> watchUserTanks(String ownerUid, {bool isDemo = false}) async* {
    yield _tanks.where((t) => t.ownerUid == ownerUid).toList();
    yield* _tanksStreamController.stream.map((list) {
      return list.where((t) => t.ownerUid == ownerUid).toList();
    });
  }

  @override
  Future<List<HomeTank>> getUserTanks(String ownerUid, {bool isDemo = false}) async {
    return _tanks.where((t) => t.ownerUid == ownerUid).toList();
  }

  @override
  Future<HomeTank?> getTankById(String tankId, {bool isDemo = false}) async {
    try {
      return _tanks.firstWhere((t) => t.id == tankId);
    } catch (_) {
      return null;
    }
  }

  bool simulateDeletionFailure = false;

  @override
  Future<void> registerTank(HomeTank tank, {bool isDemo = false}) async {
    if (tank.hasDevice) {
      final isAvailable = await verifyDeviceAvailability(tank.deviceId!, tank.ownerUid, isDemo: isDemo);
      if (!isAvailable) {
        throw Exception('Device "${tank.deviceId}" is already registered to another user.');
      }
    }

    final existingIdx = _tanks.indexWhere((t) => t.id == tank.id);
    if (existingIdx >= 0) {
      if (_tanks[existingIdx].ownerUid != tank.ownerUid) {
        throw Exception('Unauthorized: Cannot modify a tank owned by another user.');
      }
      _tanks[existingIdx] = tank;
    } else {
      _tanks.add(tank);
    }
    _tanksStreamController.add(List.from(_tanks));
  }

  @override
  Future<void> updateTank(HomeTank tank, {bool isDemo = false}) async {
    final index = _tanks.indexWhere((t) => t.id == tank.id);
    if (index >= 0) {
      if (_tanks[index].ownerUid != tank.ownerUid) {
        throw Exception('Unauthorized: Cannot modify a tank owned by another user.');
      }
      if (tank.hasDevice && tank.deviceId != _tanks[index].deviceId) {
        final isAvailable = await verifyDeviceAvailability(tank.deviceId!, tank.ownerUid, isDemo: isDemo);
        if (!isAvailable) {
          throw Exception('Device "${tank.deviceId}" is already registered to another user.');
        }
      }
      _tanks[index] = tank;
      _tanksStreamController.add(List.from(_tanks));
    }
  }

  @override
  Future<void> deleteTank(String tankId, {bool isDemo = false}) async {
    if (simulateDeletionFailure) {
      throw Exception('Simulated database network error during deletion of $tankId');
    }
    final index = _tanks.indexWhere((t) => t.id == tankId);
    if (index >= 0) {
      _tanks.removeAt(index);
      _readings.remove(tankId);
      _tanksStreamController.add(List.from(_tanks));
    }
  }

  @override
  Stream<List<TankReading>> watchTankReadings(String tankId, {bool isDemo = false}) async* {
    yield _readings[tankId] ?? <TankReading>[];
  }

  @override
  Future<void> addTankReading(TankReading reading, {bool isDemo = false}) async {
    final list = _readings[reading.tankId] ?? [];
    list.insert(0, reading);
    _readings[reading.tankId] = list;

    // Update parent tank cached reading
    final tankIdx = _tanks.indexWhere((t) => t.id == reading.tankId);
    if (tankIdx >= 0) {
      _tanks[tankIdx] = _tanks[tankIdx].copyWith(
        ph: reading.ph,
        tdsEc: reading.tdsEc,
        turbidity: reading.turbidity,
        temperature: reading.temperature,
        status: reading.status,
        lastReadingAt: reading.timestamp,
        updatedAt: DateTime.now(),
      );
      _tanksStreamController.add(List.from(_tanks));
    }
  }

  @override
  Future<bool> verifyDeviceAvailability(String deviceId, String ownerUid, {bool isDemo = false}) async {
    if (deviceId.trim().isEmpty) return true;
    for (final tank in _tanks) {
      if (tank.deviceId?.trim().toLowerCase() == deviceId.trim().toLowerCase()) {
        if (tank.ownerUid != ownerUid) {
          return false; // Owned by another user
        }
      }
    }
    return true;
  }
}
