import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.bio = '',
    this.photoUrl = '',
    this.role = '',
    this.location = '',
    this.cvUrl = '',
    this.cvName = '',
  });

  final String uid;
  final String name;
  final String email;
  final String bio;
  final String photoUrl;
  final String role;

  /// Kigali neighborhood the user works from (AppConstants.neighborhoods).
  final String location;

  /// Firebase Storage download URL of the user's CV (PDF), if uploaded.
  final String cvUrl;

  /// Original file name of the CV, shown on the profile.
  final String cvName;

  bool get hasCv => cvUrl.isNotEmpty;

  @override
  List<Object?> get props => [
    uid,
    name,
    email,
    bio,
    photoUrl,
    role,
    location,
    cvUrl,
    cvName,
  ];
}
