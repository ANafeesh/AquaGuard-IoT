import 'dart:async';
import '../../services/local_storage_service.dart';
import '../auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _authController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  MockAuthRepository() {
    _initFromStorage();
  }

  void _initFromStorage() {
    final storage = LocalStorageService.instance;
    final email = storage.getString('auth_email');
    final name = storage.getString('auth_name');
    final id = storage.getString('auth_id');

    if (email != null && id != null) {
      _currentUser = AppUser(
        id: id,
        email: email,
        displayName: name ?? email.split('@').first,
        role: 'Community Water Monitor',
        observationsCount: storage.getMap('user_stats')?['observations'] ?? 6,
        monitoredSourcesCount: storage.getStringList('saved_sources').isNotEmpty
            ? storage.getStringList('saved_sources').length
            : 5,
        daysActive: 28,
      );
    } else {
      // Default initial mock user for first-time prototype exploration
      _currentUser = const AppUser(
        id: 'usr-mock-1',
        email: 'user@example.com',
        displayName: 'AquaGuard User',
        role: 'Community Water Monitor',
        observationsCount: 6,
        monitoredSourcesCount: 5,
        daysActive: 28,
      );
    }
    _authController.add(_currentUser);
  }

  @override
  Stream<AppUser?> watchCurrentUser() async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  AppUser? getCurrentUser() => _currentUser;

  @override
  Future<AppUser> signIn(String email, String password) async {
    final storage = LocalStorageService.instance;
    final name = email.split('@').first;
    _currentUser = AppUser(
      id: 'usr-mock-${email.hashCode.abs()}',
      email: email,
      displayName: name,
      role: 'Community Water Monitor',
      observationsCount: 6,
      monitoredSourcesCount: 5,
      daysActive: 28,
    );

    await storage.setString('auth_id', _currentUser!.id);
    await storage.setString('auth_email', _currentUser!.email);
    await storage.setString('auth_name', _currentUser!.displayName);

    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AppUser> signUp(String email, String password, {String? displayName}) async {
    final storage = LocalStorageService.instance;
    final name = displayName ?? email.split('@').first;
    _currentUser = AppUser(
      id: 'usr-mock-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      role: 'Community Water Monitor',
      observationsCount: 0,
      monitoredSourcesCount: 1,
      daysActive: 1,
    );

    await storage.setString('auth_id', _currentUser!.id);
    await storage.setString('auth_email', _currentUser!.email);
    await storage.setString('auth_name', _currentUser!.displayName);

    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    final storage = LocalStorageService.instance;
    await storage.remove('auth_id');
    await storage.remove('auth_email');
    await storage.remove('auth_name');

    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    // Simulated password reset in mock mode
  }
}
