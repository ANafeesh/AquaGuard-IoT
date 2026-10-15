import '../models/home_tank.dart';
import '../models/tank_reading.dart';

/// Contract interface for managing private residential home water tanks
abstract class HomeTankRepository {
  /// Stream of all home tanks owned by a specific authenticated user.
  /// Strictly private to [ownerUid].
  Stream<List<HomeTank>> watchUserTanks(String ownerUid, {bool isDemo = false});

  /// Fetch all home tanks owned by [ownerUid].
  Future<List<HomeTank>> getUserTanks(String ownerUid, {bool isDemo = false});

  /// Fetch a single tank by [tankId]. Returns null if not found.
  Future<HomeTank?> getTankById(String tankId, {bool isDemo = false});

  /// Register a new home tank. Must be owned by the authenticated user.
  Future<void> registerTank(HomeTank tank, {bool isDemo = false});

  /// Update an existing home tank's details. Must preserve ownerUid.
  Future<void> updateTank(HomeTank tank, {bool isDemo = false});

  /// Delete a home tank registration and its private telemetry.
  Future<void> deleteTank(String tankId, {bool isDemo = false});

  /// Stream historical telemetry readings for a specific private home tank.
  Stream<List<TankReading>> watchTankReadings(String tankId, {bool isDemo = false});

  /// Append a new sensor reading to the private tank subcollection.
  Future<void> addTankReading(TankReading reading, {bool isDemo = false});

  /// Verifies whether an ESP32 [deviceId] is available to be linked to this [ownerUid].
  /// Returns false if the device is already claimed by another user.
  Future<bool> verifyDeviceAvailability(String deviceId, String ownerUid, {bool isDemo = false});
}
