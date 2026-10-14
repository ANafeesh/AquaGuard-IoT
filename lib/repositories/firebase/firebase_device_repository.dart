import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../models/device.dart';
import '../../core/services/demo_simulator_service.dart';
import '../device_repository.dart';

class FirebaseDeviceRepository implements DeviceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection({bool isDemo = false}) =>
      _firestore.collection(AppConfig.getDevicesCollection(isDemo: isDemo));

  @override
  Stream<List<Device>> watchDevices({bool isDemo = false}) {
    if (isDemo) {
      return Stream.value(DemoSimulatorService.getDemoDevices());
    }

    return _collection(isDemo: isDemo).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Device.fromJson(data);
      }).toList();
    });
  }

  @override
  Future<List<Device>> getDevices({bool isDemo = false}) async {
    if (isDemo) {
      return DemoSimulatorService.getDemoDevices();
    }

    try {
      final snapshot = await _collection(isDemo: isDemo).get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return Device.fromJson(data);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> updateDeviceHeartbeat(String deviceId, {bool isDemo = false}) async {
    try {
      await _collection(isDemo: isDemo).doc(deviceId).update({
        'lastSeenAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Future<void> registerDevice(Device device, {bool isDemo = false}) async {
    await _collection(isDemo: isDemo).doc(device.id).set(device.toJson());
  }
}
