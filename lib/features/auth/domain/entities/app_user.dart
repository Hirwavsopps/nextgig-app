import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    this.name = '',
    this.emailVerified = false,
  });

  final String uid;
  final String email;
  final String name;
  final bool emailVerified;

  @override
  List<Object?> get props => [uid, email, name, emailVerified];
}
