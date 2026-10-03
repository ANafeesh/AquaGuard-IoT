import '../auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  @override
  Stream<AppUser?> watchCurrentUser() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  AppUser? getCurrentUser() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<AppUser> signIn(String email, String password) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<AppUser> signUp(String email, String password, {String? displayName}) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> signOut() {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }

  @override
  Future<void> sendPasswordReset(String email) {
    throw UnimplementedError('Firebase backend configuration required in Phase B.');
  }
}
