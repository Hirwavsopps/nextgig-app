import 'package:equatable/equatable.dart';

/// A person trusted to approve or reject skill evidence (reviewers/{uid}).
///
/// The app can only read these documents. They are created by the project
/// owner in the Firebase Console or with tool/seed.mjs, so signing up as a
/// "mentor" does not make anyone a reviewer.
class Reviewer extends Equatable {
  const Reviewer({
    required this.uid,
    required this.name,
    required this.relationship,
    this.title = '',
    this.organization = '',
    this.active = false,
  });

  final String uid;
  final String name;

  /// mentor, lecturer or client. Shown next to the endorsement.
  final String relationship;
  final String title;
  final String organization;
  final bool active;

  static const relationships = ['mentor', 'lecturer', 'client'];

  String get relationshipLabel => switch (relationship) {
    'lecturer' => 'Lecturer',
    'client' => 'Past client',
    _ => 'Mentor',
  };

  @override
  List<Object?> get props => [
    uid,
    name,
    relationship,
    title,
    organization,
    active,
  ];
}
