import 'package:firebase_auth/firebase_auth.dart';
import '../auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser _mapFirebaseUser(User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? (user.isAnonymous ? 'guest@aquaguard.local' : ''),
      displayName: user.displayName ??
          (user.isAnonymous
              ? 'Guest Observer'
              : (user.email?.isNotEmpty == true
                  ? user.email!.split('@').first
                  : 'AquaGuard User')),
      role: user.isAnonymous ? 'Guest Observer' : 'Community Water Monitor',
      isGuest: user.isAnonymous,
    );
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return _mapFirebaseUser(user);
    });
  }

  @override
  AppUser? getCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _mapFirebaseUser(user);
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _mapFirebaseUser(cred.user!);
  }

  @override
  Future<AppUser> signUp(String email, String password, {String? displayName}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.trim().isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    return _mapFirebaseUser(cred.user!);
  }

  @override
  Future<AppUser> continueAsGuest() async {
    final cred = await _auth.signInAnonymously();
    return _mapFirebaseUser(cred.user!);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
