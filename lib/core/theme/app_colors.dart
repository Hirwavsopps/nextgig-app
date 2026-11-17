import 'package:flutter/material.dart';

/// Colors sampled from the Figma prototype screenshots.
/// If the designers change a color in Figma, change it here and nowhere else.
class AppColors {
  const AppColors._();

  /// Screen background.
  static const Color background = Color(0xFFF9F9FB);

  /// Cards and sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// Chips, input fields and tiles.
  static const Color fill = Color(0xFFF3F3F5);

  /// Card and field outlines.
  static const Color border = Color(0xFFE2E2E4);

  /// Main text.
  static const Color ink = Color(0xFF1A1C1D);

  /// Buttons, logo and selected chips.
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Secondary text (6:1 contrast on the background).
  static const Color muted = Color(0xFF5F5E60);

  /// Log out button background and error color.
  static const Color dangerFill = Color(0xFFFFDAD6);
  static const Color danger = Color(0xFFB3261E);

  static const Color success = Color(0xFF2E7D32);
}
