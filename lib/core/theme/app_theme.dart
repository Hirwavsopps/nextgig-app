import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/theme/app_colors.dart';

class AppRadii {
  const AppRadii._();

  static const double card = 20;
  static const double control = 16;
}

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData _theme({
    required ColorScheme scheme,
    required Color scaffold,
    required Color navBackground,
    required Color navSelected,
    required Color navUnselected,
  }) {
    final controlRadius = BorderRadius.circular(AppRadii.control);
    final controlShape = RoundedRectangleBorder(borderRadius: controlRadius);
    OutlineInputBorder fieldBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: controlRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: controlShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
          shape: controlShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: fieldBorder(scheme.outlineVariant),
        enabledBorder: fieldBorder(scheme.outlineVariant),
        focusedBorder: fieldBorder(scheme.primary, width: 1.4),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.primary;
            return scheme.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return scheme.onPrimary;
            return scheme.onSurface;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
      navigationBarTheme: _navigationBarTheme(
        background: navBackground,
        selected: navSelected,
        unselected: navUnselected,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme({
    required Color background,
    required Color selected,
    required Color unselected,
  }) {
    return NavigationBarThemeData(
      backgroundColor: background,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return IconThemeData(color: isSelected ? selected : unselected);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final isSelected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? selected : unselected,
        );
      }),
    );
  }

  static ThemeData get light => _theme(
    scheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerHighest: AppColors.fill,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
    ),
    scaffold: AppColors.background,
    navBackground: AppColors.surface,
    navSelected: AppColors.primary,
    navUnselected: AppColors.muted,
  );

  static ThemeData get dark => _theme(
    scheme: const ColorScheme.dark(
      primary: AppColors.onPrimary,
      onPrimary: AppColors.primary,
      secondary: AppColors.accent,
      onSecondary: AppColors.primary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      onSurfaceVariant: AppColors.darkMuted,
      surfaceContainerHighest: AppColors.darkFill,
      outlineVariant: AppColors.darkBorder,
      error: Color(0xFFFFB4AB),
    ),
    scaffold: AppColors.darkBackground,
    navBackground: AppColors.darkSurface,
    navSelected: AppColors.darkInk,
    navUnselected: AppColors.darkMuted,
  );
}
