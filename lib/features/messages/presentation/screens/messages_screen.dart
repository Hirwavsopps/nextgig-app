import 'package:flutter/material.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';

/// TODO: replace this placeholder with the real screen.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Messages',
      note: 'Messages between users.',
    );
  }
}
