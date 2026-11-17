import 'package:flutter/material.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';

/// TODO: replace this placeholder with the real screen.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profile',
      note: 'Skill profile and settings - owned by the profile member.',
    );
  }
}
