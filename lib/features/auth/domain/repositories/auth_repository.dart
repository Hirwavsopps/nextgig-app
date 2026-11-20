import 'package:nextgig/features/auth/domain/entities/app_user.dart';
import 'package:nextgig/features/auth/domain/entities/user_role.dart';

/// Thrown by the repository with a user-friendly message.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  });
  Future<void> signIn({required String email, required String password});
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> sendEmailVerification();
  Future<void> reloadUser();
  Future<void> signOut();
}
