import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/auth/domain/entities/app_user.dart';
import 'package:nextgig/features/auth/domain/entities/user_role.dart';
import 'package:nextgig/features/auth/domain/repositories/auth_repository.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  const user = AppUser(
    uid: 'u1',
    email: 'amina@mail.com',
    name: 'Amina',
    emailVerified: true,
  );

  setUpAll(() {
    registerFallbackValue(UserRole.talent);
  });

  setUp(() {
    repository = MockAuthRepository();
    when(() => repository.currentUser).thenReturn(null);
    when(() => repository.authStateChanges())
        .thenAnswer((_) => const Stream<AppUser?>.empty());
  });

  blocTest<AuthCubit, AuthState>(
    'becomes authenticated when Firebase reports a signed-in user',
    setUp: () {
      when(() => repository.authStateChanges())
          .thenAnswer((_) => Stream<AppUser?>.value(user));
    },
    build: () => AuthCubit(repository),
    wait: const Duration(milliseconds: 10),
    expect: () => [const AuthState(user: user, initialized: true)],
  );

  blocTest<AuthCubit, AuthState>(
    'shows a friendly error when sign-in fails',
    setUp: () {
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => throw const AuthFailure('Incorrect email or password.'),
      );
    },
    build: () => AuthCubit(repository),
    act: (cubit) => cubit.signIn('amina@mail.com', 'password123'),
    expect: () => [
      const AuthState(initialized: true, busy: true),
      const AuthState(initialized: true, error: 'Incorrect email or password.'),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'tells the user the reset email was sent',
    setUp: () {
      when(() => repository.sendPasswordReset(any())).thenAnswer((_) async {});
    },
    build: () => AuthCubit(repository),
    act: (cubit) => cubit.resetPassword('amina@mail.com'),
    expect: () => [
      const AuthState(initialized: true, busy: true),
      const AuthState(
        initialized: true,
        info: 'Password reset email sent. Check your inbox.',
      ),
    ],
  );

  test('signUp forwards the chosen role and phone to the repository', () async {
    when(
      () => repository.signUp(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        role: any(named: 'role'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async {});

    final cubit = AuthCubit(repository);
    await cubit.signUp(
      'Amina',
      'amina@mail.com',
      'password123',
      role: UserRole.mentor,
      phone: '0788123456',
    );

    verify(
      () => repository.signUp(
        name: 'Amina',
        email: 'amina@mail.com',
        password: 'password123',
        role: UserRole.mentor,
        phone: '0788123456',
      ),
    ).called(1);
    await cubit.close();
  });
}
