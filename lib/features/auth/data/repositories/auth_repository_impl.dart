import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nextgig/features/auth/domain/entities/app_user.dart';
import 'package:nextgig/features/auth/domain/entities/user_role.dart';
import 'package:nextgig/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Google Sign-In must be initialized once per app run.
  static bool _googleInitialized = false;

  AppUser _toUser(User u) => AppUser(
    uid: u.uid,
    email: u.email ?? '',
    name: u.displayName ?? '',
    emailVerified: u.emailVerified,
  );

  @override
  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().map((u) => u == null ? null : _toUser(u));

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : _toUser(u);
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) return;
      await user.updateDisplayName(name.trim());
      await _createProfileIfMissing(
        user,
        name: name.trim(),
        role: role,
        phone: phone,
      );
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _ensureProfileQuietly(cred.user);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_googleInitialized) {
        await googleSignIn.initialize();
        _googleInitialized = true;
      }
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      final cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      await _ensureProfileQuietly(cred.user);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      throw const AuthFailure('Google sign-in failed. Please try again.');
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_message(e.code));
    }
  }

  @override
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Creates users/{uid} the first time a user appears. Never overwrites.
  Future<void> _createProfileIfMissing(
    User user, {
    required UserRole role,
    String? name,
    String? phone,
  }) async {
    try {
      final ref = _firestore.collection('users').doc(user.uid);
      final snapshot = await ref.get();
      if (snapshot.exists) return;
      await ref.set({
        'name': name ?? user.displayName ?? '',
        'email': user.email ?? '',
        'phone': phone ?? '',
        'role': role.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const AuthFailure(
        'Your account was created, but saving your profile failed. '
        'Please try again.',
      );
    }
  }

  /// Used on login: accounts created before profiles existed get one now.
  /// A failure here must not block the login itself.
  Future<void> _ensureProfileQuietly(User? user) async {
    if (user == null) return;
    try {
      await _createProfileIfMissing(user, role: UserRole.talent);
    } on AuthFailure {
      // The profile is created on the next successful login instead.
    }
  }

  /// Maps Firebase error codes to friendly messages for the UI.
  String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
