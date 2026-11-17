import 'package:flutter/material.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';

/// TODO: replace this placeholder with the real screen.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Log in',
      note: 'Login screen - owned by the authentication member.',
    );
  }
}
