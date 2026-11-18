import 'package:flutter/material.dart';
import 'package:nextgig/features/auth/presentation/widgets/account_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: AccountSection(),
        ),
      ),
    );
  }
}
