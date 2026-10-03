import '../../models/water_source.dart';
import '../water_source_repository.dart';

class FirebaseWaterSourceRepository implements WaterSourceRepository {
  @override
  Stream<List<WaterSource>> watchWaterSources() {
    // Will connect to FirebaseFirestore in Phase B/C
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<WaterSource?> getWaterSourceById(String id) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<WaterSource> getActiveWaterSource() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> setActiveWaterSourceId(String id) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }
}
