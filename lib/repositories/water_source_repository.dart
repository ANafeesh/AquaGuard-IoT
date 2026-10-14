import '../models/water_source.dart';

abstract class WaterSourceRepository {
  /// Stream list of all monitored water sources
  Stream<List<WaterSource>> watchWaterSources();

  /// Retrieve a specific water source by ID
  Future<WaterSource?> getWaterSourceById(String id);

  /// Get the currently active/default water source
  Future<WaterSource> getActiveWaterSource();

  /// Update the locally selected water source
  Future<void> setActiveWaterSourceId(String id);

  /// Add or update a water source
  Future<void> addWaterSource(WaterSource source);

  /// Delete a water source by ID
  Future<void> deleteWaterSource(String id);
}
