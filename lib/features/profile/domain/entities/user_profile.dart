import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.bio = '',
    this.photoUrl = '',
    this.role = '',
  });

  final String uid;
  final String name;
  final String email;
  final String bio;
  final String photoUrl;
  final String role;

  @override
  List<Object?> get props => [uid, name, email, bio, photoUrl, role];
}
