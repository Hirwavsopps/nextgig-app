/// What the user chose at sign-up. Stored as `role` in users/{uid}.
enum UserRole {
  talent,
  mentor;

  String get label => this == UserRole.talent ? 'Talent' : 'Mentor';
}
