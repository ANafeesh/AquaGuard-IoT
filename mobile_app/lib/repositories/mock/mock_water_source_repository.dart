import 'dart:async';
import '../../models/water_source.dart';
import '../../data/mock_data.dart';
import '../water_source_repository.dart';

class MockWaterSourceRepository implements WaterSourceRepository {
  final _controller = StreamController<List<WaterSource>>.broadcast();
  String _activeSourceId = MockData.waterSources.first.id;

  MockWaterSourceRepository() {
    _controller.add(MockData.waterSources);
  }

  @override
  Stream<List<WaterSource>> watchWaterSources() async* {
    yield MockData.waterSources;
    yield* _controller.stream;
  }

  @override
  Future<WaterSource?> getWaterSourceById(String id) async {
    try {
      return MockData.waterSources.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<WaterSource> getActiveWaterSource() async {
    return MockData.waterSources.firstWhere(
      (s) => s.id == _activeSourceId,
      orElse: () => MockData.waterSources.first,
    );
  }

  @override
  Future<void> setActiveWaterSourceId(String id) async {
    _activeSourceId = id;
    _controller.add(MockData.waterSources);
  }
}
