import '../models/device.dart';

abstract class DeviceRepository {
  /// Stream of IoT sensor devices
  Stream<List<Device>> watchDevices({bool isDemo = false});

  /// Retrieve list of devices
  Future<List<Device>> getDevices({bool isDemo = false});

  /// Record a heartbeat timestamp for an active device
  Future<void> updateDeviceHeartbeat(String deviceId, {bool isDemo = false});

  /// Register a new device node
  Future<void> registerDevice(Device device, {bool isDemo = false});
}
