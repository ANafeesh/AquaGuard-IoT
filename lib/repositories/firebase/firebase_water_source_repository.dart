import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/app_config.dart';
import '../../models/water_source.dart';
import '../../services/local_storage_service.dart';
import '../../data/mock_data.dart';
import '../water_source_repository.dart';

class FirebaseWaterSourceRepository implements WaterSourceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _activeSourceStorageKey = 'aquaguard_active_source_id';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConfig.getSourcesCollection());

  @override
  Stream<List<WaterSource>> watchWaterSources() async* {
    // Instantly emit baseline sources (0ms delay) so UI never hangs in loading state
    yield MockData.waterSources;

    // Stream live Firestore updates as soon as network data arrives
    yield* _collection.snapshots().map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return WaterSource.fromJson(data);
        }).toList();
      }
      return MockData.waterSources;
    }).handleError((_) => MockData.waterSources);
  }

  @override
  Future<WaterSource?> getWaterSourceById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      data['id'] = doc.id;
      return WaterSource.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WaterSource> getActiveWaterSource() async {
    final activeId = LocalStorageService.instance.getString(_activeSourceStorageKey);
    if (activeId != null && activeId.isNotEmpty) {
      final cached = await getWaterSourceById(activeId);
      if (cached != null) return cached;
    }

    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        final data = Map<String, dynamic>.from(snapshot.docs.first.data());
        data['id'] = snapshot.docs.first.id;
        return WaterSource.fromJson(data);
      }
    } catch (_) {}

    // Fallback default source if Firestore collection is initially empty
    return WaterSource(
      id: 'default_source',
      name: 'Monitored Catchment Station',
      type: WaterSourceType.river,
      latitude: 6.9271,
      longitude: 79.8612,
      createdBy: 'system',
      createdAt: DateTime.now(),
      status: WaterQualityStatus.withinTypicalRange,
      ph: 7.2,
      tdsEc: 320,
      turbidity: 2.5,
      temperature: 27.5,
      description: 'Connected Cloud Firestore Water Monitoring Station',
    );
  }

  @override
  Future<void> setActiveWaterSourceId(String id) async {
    await LocalStorageService.instance.setString(_activeSourceStorageKey, id);
  }

  @override
  Future<void> addWaterSource(WaterSource source) async {
    await _collection.doc(source.id).set(source.toJson());
  }

  @override
  Future<void> deleteWaterSource(String id) async {
    await _collection.doc(id).delete();
  }
}
