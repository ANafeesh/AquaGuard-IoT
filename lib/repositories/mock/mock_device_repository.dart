import 'dart:async';
import '../../models/device.dart';
import '../../core/services/demo_simulator_service.dart';
import '../device_repository.dart';

class MockDeviceRepository implements DeviceRepository {
  final _controller = StreamController<List<Device>>.broadcast();
  List<Device> _devices = [];

  MockDeviceRepository() {
    _init();
  }

  void _init() {
    final now = DateTime.now();
    _devices = [
      Device(
        id: 'esp32_river_node_01',
        name: 'ESP32 River Reach Node (GPS)',
        ownerUid: 'usr_main',
        lastSeenAt: now.subtract(const Duration(minutes: 2)), // Online (< 10 min)
        batteryLevel: 92,
        signalStrength: -65,
        firmwareVersion: 'v2.1.0-iot',
      ),
      Device(
        id: 'esp32_well_node_02',
        name: 'ESP32 Pine Well Station',
        ownerUid: 'usr_main',
        lastSeenAt: now.subtract(const Duration(minutes: 7)), // Online (< 10 min)
        batteryLevel: 78,
        signalStrength: -72,
        firmwareVersion: 'v2.1.0-iot',
      ),
      Device(
        id: 'esp32_reservoir_node_03',
        name: 'ESP32 Reservoir Station',
        ownerUid: 'usr_main',
        lastSeenAt: now.subtract(const Duration(minutes: 38)), // Offline (> 10 min)
        batteryLevel: 25,
        signalStrength: -88,
        firmwareVersion: 'v2.0.4-iot',
      ),
    ];
    _controller.add(_devices);
  }

  @override
  Stream<List<Device>> watchDevices({bool isDemo = false}) async* {
    if (isDemo) {
      yield DemoSimulatorService.getDemoDevices();
      return;
    }
    yield _devices;
    yield* _controller.stream;
  }

  @override
  Future<List<Device>> getDevices({bool isDemo = false}) async {
    if (isDemo) return DemoSimulatorService.getDemoDevices();
    return _devices;
  }

  @override
  Future<void> updateDeviceHeartbeat(String deviceId, {bool isDemo = false}) async {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(lastSeenAt: DateTime.now());
      _controller.add(List.unmodifiable(_devices));
    }
  }

  @override
  Future<void> registerDevice(Device device, {bool isDemo = false}) async {
    _devices.add(device);
    _controller.add(List.unmodifiable(_devices));
  }
}
