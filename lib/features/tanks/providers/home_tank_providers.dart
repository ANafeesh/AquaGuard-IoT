import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/home_tank.dart';
import '../../../models/tank_reading.dart';
import '../../../providers/app_state_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_preferences_provider.dart';

/// Stream of all home tanks owned by the currently authenticated user
final userHomeTanksStreamProvider = StreamProvider<List<HomeTank>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  final prefs = ref.watch(userPreferencesProvider);
  final repo = ref.watch(homeTankRepositoryProvider);

  // If user is guest/demo or not logged in, resolve default demo uid
  final effectiveUid = (user != null && user.id.isNotEmpty) ? user.id : 'usr_demo_01';

  return repo.watchUserTanks(effectiveUid, isDemo: prefs.isDemoMode);
});

/// Stream of private telemetry readings for a specific home tank
final tankReadingsStreamProvider =
    StreamProvider.family<List<TankReading>, String>((ref, tankId) {
  final repo = ref.watch(homeTankRepositoryProvider);
  final prefs = ref.watch(userPreferencesProvider);
  return repo.watchTankReadings(tankId, isDemo: prefs.isDemoMode);
});

/// Specific home tank by ID
final singleHomeTankProvider =
    Provider.family<HomeTank?, String>((ref, tankId) {
  final tanksAsync = ref.watch(userHomeTanksStreamProvider);
  return tanksAsync.when(
    data: (tanks) => tanks.firstWhere(
      (t) => t.id == tankId,
      orElse: () => throw Exception('Tank not found'),
    ),
    loading: () => null,
    error: (e, _) => null,
  );
});
