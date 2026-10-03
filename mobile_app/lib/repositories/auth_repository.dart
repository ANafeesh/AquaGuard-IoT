class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final int observationsCount;
  final int monitoredSourcesCount;
  final int daysActive;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.role = 'Community Water Monitor',
    this.observationsCount = 0,
    this.monitoredSourcesCount = 0,
    this.daysActive = 1,
  });

  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'AG';
  }
}

abstract class AuthRepository {
  /// Stream current auth user or null
  Stream<AppUser?> watchCurrentUser();

  /// Get current cached user
  AppUser? getCurrentUser();

  /// Sign in with email and password
  Future<AppUser> signIn(String email, String password);

  /// Register new user account
  Future<AppUser> signUp(String email, String password, {String? displayName});

  /// Sign out current session
  Future<void> signOut();

  /// Trigger password reset email
  Future<void> sendPasswordReset(String email);
}
