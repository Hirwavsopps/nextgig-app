import 'package:flutter/material.dart';
import 'package:nextgig/core/widgets/placeholder_screen.dart';

/// TODO: replace this placeholder with the real screen.
class PostingsScreen extends StatelessWidget {
  const PostingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Gigs',
      note: 'Gig postings and applications - owned by the postings member.',
    );
  }
}
