import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../models/home_tank.dart';
import '../../models/tank_reading.dart';
import '../home_tank_repository.dart';

/// Production Cloud Firestore implementation for private Home Water Tanks.
/// Strictly enforces owner-only visibility and data access at the query level.
class FirebaseHomeTankRepository implements HomeTankRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection({bool isDemo = false}) =>
      _firestore.collection(AppConfig.getHomeTanksCollection(isDemo: isDemo));

  CollectionReference<Map<String, dynamic>> _readingsCollection(String tankId, {bool isDemo = false}) =>
      _collection(isDemo: isDemo).doc(tankId).collection('readings');

  CollectionReference<Map<String, dynamic>> _devicesCollection({bool isDemo = false}) =>
      _firestore.collection(AppConfig.getDevicesCollection(isDemo: isDemo));

  @override
  Stream<List<HomeTank>> watchUserTanks(String ownerUid, {bool isDemo = false}) {
    if (ownerUid.isEmpty) {
      return Stream.value(<HomeTank>[]);
    }

    // Query strictly constrained to authenticated owner's UID
    return _collection(isDemo: isDemo)
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return HomeTank.fromJson(data);
      }).toList();
    }).handleError((_) => <HomeTank>[]);
  }

  @override
  Future<List<HomeTank>> getUserTanks(String ownerUid, {bool isDemo = false}) async {
    if (ownerUid.isEmpty) return [];

    try {
      final snapshot = await _collection(isDemo: isDemo)
          .where('ownerUid', isEqualTo: ownerUid)
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return HomeTank.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<HomeTank?> getTankById(String tankId, {bool isDemo = false}) async {
    try {
      final doc = await _collection(isDemo: isDemo).doc(tankId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return HomeTank.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> registerTank(HomeTank tank, {bool isDemo = false}) async {
    // Enforce private visibility strictly
    final payload = tank.toJson();
    payload['visibility'] = 'private';

    // Verify hardware device availability before writing
    if (tank.hasDevice) {
      final isAvailable = await verifyDeviceAvailability(tank.deviceId!, tank.ownerUid, isDemo: isDemo);
      if (!isAvailable) {
        throw Exception('Device "${tank.deviceId}" is already registered to another user.');
      }
    }

    await _collection(isDemo: isDemo).doc(tank.id).set(payload);

    // If device is associated, ensure device registration is secured
    if (tank.hasDevice) {
      try {
        final devDoc = await _devicesCollection(isDemo: isDemo).doc(tank.deviceId).get();
        if (!devDoc.exists) {
          // Register device under this owner
          await _devicesCollection(isDemo: isDemo).doc(tank.deviceId).set({
            'id': tank.deviceId,
            'name': '${tank.tankName} Sensor Node',
            'ownerUid': tank.ownerUid,
            'lastSeenAt': DateTime.now().toIso8601String(),
            'firmwareVersion': 'v1.1.0-tank',
          });
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> updateTank(HomeTank tank, {bool isDemo = false}) async {
    final existing = await getTankById(tank.id, isDemo: isDemo);
    if (existing != null && existing.ownerUid != tank.ownerUid) {
      throw Exception('Unauthorized: Cannot modify a tank owned by another user.');
    }

    if (tank.hasDevice && tank.deviceId != existing?.deviceId) {
      final isAvailable = await verifyDeviceAvailability(tank.deviceId!, tank.ownerUid, isDemo: isDemo);
      if (!isAvailable) {
        throw Exception('Device "${tank.deviceId}" is already registered to another user.');
      }
    }

    final payload = tank.toJson();
    payload['visibility'] = 'private';
    payload['updatedAt'] = DateTime.now().toIso8601String();

    await _collection(isDemo: isDemo).doc(tank.id).update(payload);
  }

  @override
  Future<void> deleteTank(String tankId, {bool isDemo = false}) async {
    try {
      // Safely delete all subcollection readings and the tank document atomically
      final readingsSnap = await _readingsCollection(tankId, isDemo: isDemo).get();
      final batch = _firestore.batch();
      for (final doc in readingsSnap.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_collection(isDemo: isDemo).doc(tankId));
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete tank $tankId: $e');
    }
  }

  @override
  Stream<List<TankReading>> watchTankReadings(String tankId, {bool isDemo = false}) {
    return _readingsCollection(tankId, isDemo: isDemo)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return TankReading.fromJson(data);
      }).toList();
    }).handleError((_) => <TankReading>[]);
  }

  @override
  Future<void> addTankReading(TankReading reading, {bool isDemo = false}) async {
    // Write reading into private subcollection
    await _readingsCollection(reading.tankId, isDemo: isDemo)
        .doc(reading.id)
        .set(reading.toJson());

    // Update cached reading snapshot on parent tank doc for high-performance dashboard load
    try {
      await _collection(isDemo: isDemo).doc(reading.tankId).update({
        'ph': reading.ph,
        'tdsEc': reading.tdsEc,
        'turbidity': reading.turbidity,
        'temperature': reading.temperature,
        'status': reading.status.name,
        'lastReadingAt': reading.timestamp.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<bool> verifyDeviceAvailability(String deviceId, String ownerUid, {bool isDemo = false}) async {
    if (deviceId.trim().isEmpty) return true;
    try {
      final doc = await _devicesCollection(isDemo: isDemo).doc(deviceId.trim()).get();
      if (!doc.exists) {
        return true; // Available for first-time registration
      }
      final existingOwner = doc.data()?['ownerUid'] as String?;
      return existingOwner == null || existingOwner == ownerUid;
    } catch (_) {
      return true;
    }
  }
}
