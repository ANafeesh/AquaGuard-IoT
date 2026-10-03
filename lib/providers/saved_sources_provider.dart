import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/water_source.dart';
import '../services/local_storage_service.dart';
import 'app_state_providers.dart';

class SavedSourcesNotifier extends Notifier<List<String>> {
  static const String _storageKey = 'saved_source_ids';

  @override
  List<String> build() {
    final storage = LocalStorageService.instance;
    final saved = storage.getStringList(_storageKey);
    if (saved.isNotEmpty) {
      return saved;
    }
    // Default initial bookmarked sources for new users
    return ['ws-1', 'ws-2', 'ws-3'];
  }

  Future<void> toggleBookmark(String sourceId) async {
    final current = List<String>.from(state);
    if (current.contains(sourceId)) {
      current.remove(sourceId);
    } else {
      current.add(sourceId);
    }
    state = current;
    await LocalStorageService.instance.setStringList(_storageKey, current);
  }

  bool isBookmarked(String sourceId) => state.contains(sourceId);
}

final savedSourceIdsProvider =
    NotifierProvider<SavedSourcesNotifier, List<String>>(SavedSourcesNotifier.new);

/// List of actual WaterSource objects that are bookmarked
final savedWaterSourcesProvider = Provider<List<WaterSource>>((ref) {
  final allSourcesAsync = ref.watch(waterSourcesStreamProvider);
  final savedIds = ref.watch(savedSourceIdsProvider);

  return allSourcesAsync.when(
    data: (sources) => sources.where((s) => savedIds.contains(s.id)).toList(),
    loading: () => [],
    error: (err, stack) => [],
  );
});
