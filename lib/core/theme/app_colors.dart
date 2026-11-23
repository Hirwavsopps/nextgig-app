import 'package:material_ui/material_ui.dart';

/// Black is the brand color. Brass is the only accent, shared by light and dark.
class AppColors {
  const AppColors._();

  /// Screen background.
  static const Color background = Color(0xFFF6F3EE);

  /// Cards and sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// Chips, input fields and tiles.
  static const Color fill = Color(0xFFEFEAE3);

  /// Card and field outlines.
  static const Color border = Color(0xFFE4DDD4);

  /// Main text.
  static const Color ink = Color(0xFF141210);

  /// Buttons, logo and selected chips.
  static const Color primary = Color(0xFF000000);
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Pay, links and category marks. Sits next to black without competing with it.
  static const Color accent = Color(0xFFA6843D);

  /// Secondary text (about 6:1 on the paper background).
  static const Color muted = Color(0xFF6B6560);

  static const Color darkBackground = Color(0xFF0C0C0C);
  static const Color darkSurface = Color(0xFF161616);
  static const Color darkFill = Color(0xFF242220);
  static const Color darkBorder = Color(0xFF3A342C);
  static const Color darkInk = Color(0xFFF3EFE8);
  static const Color darkMuted = Color(0xFFB7B0A6);

  /// Log out button background and error color.
  static const Color dangerFill = Color(0xFFFFDAD6);
  static const Color danger = Color(0xFFB3261E);

  static const Color success = Color(0xFF2E7D32);
}
