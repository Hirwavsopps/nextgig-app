import 'dart:convert';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

/// A round profile picture with the first letter as a fallback.
///
/// [photoUrl] can be:
///  - a normal web address (a Cloudinary upload or a Google account photo), or
///  - a `data:image/jpeg;base64,...` string with the image bytes inline.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  static ImageProvider? imageFor(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    if (photoUrl.startsWith('data:image')) {
      final comma = photoUrl.indexOf(',');
      if (comma < 0) return null;
      try {
        final Uint8List bytes = base64Decode(photoUrl.substring(comma + 1));
        return MemoryImage(bytes);
      } catch (_) {
        return null; // corrupted data: show the letter instead
      }
    }
    return NetworkImage(photoUrl);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = imageFor(photoUrl);
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      backgroundImage: image,
      // A broken link falls back to the letter instead of an empty circle.
      onBackgroundImageError: image == null ? null : (_, _) {},
      child: image == null
          ? Text(
              letter,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}
