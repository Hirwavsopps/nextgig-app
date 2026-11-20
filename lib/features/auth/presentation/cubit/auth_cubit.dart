import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/auth/domain/entities/app_user.dart';
import 'package:nextgig/features/auth/domain/entities/user_role.dart';
import 'package:nextgig/features/auth/domain/repositories/auth_repository.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.initialized = false,
    this.busy = false,
    this.error,
    this.info,
  });

  final AppUser? user;
  final bool initialized;
  final bool busy;
  final String? error;
  final String? info;

  bool get isAuthenticated => user != null;

  @override
  List<Object?> get props => [user, initialized, busy, error, info];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repo) : super(const AuthState()) {
    _sub = _repo.authStateChanges().listen(
      (user) => emit(AuthState(user: user, initialized: true)),
    );
  }

  final AuthRepository _repo;
  late final StreamSubscription<AppUser?> _sub;

  Future<void> signIn(String email, String password) =>
      _run(() => _repo.signIn(email: email, password: password));

  Future<void> signUp(
    String name,
    String email,
    String password, {
    required UserRole role,
    String? phone,
  }) => _run(
    () => _repo.signUp(
      name: name,
      email: email,
      password: password,
      role: role,
      phone: phone,
    ),
  );

  Future<void> resetPassword(String email) => _run(
    () => _repo.sendPasswordReset(email),
    info: 'Password reset email sent. Check your inbox.',
  );

  Future<void> signInWithGoogle() => _run(_repo.signInWithGoogle);

  Future<void> resendVerification() => _run(
    _repo.sendEmailVerification,
    info: 'Verification email sent. Check your inbox.',
  );

  Future<void> refreshUser() async {
    await _repo.reloadUser();
    emit(AuthState(user: _repo.currentUser, initialized: true));
  }

  Future<void> signOut() => _repo.signOut();

  Future<void> _run(Future<void> Function() action, {String? info}) async {
    emit(AuthState(user: state.user, initialized: true, busy: true));
    try {
      await action();
      emit(AuthState(user: _repo.currentUser, initialized: true, info: info));
    } on AuthFailure catch (e) {
      emit(AuthState(user: state.user, initialized: true, error: e.message));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
