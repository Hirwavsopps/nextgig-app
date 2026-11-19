import 'package:flutter/material.dart';
import 'package:nextgig/core/theme/app_colors.dart';

class AppRadii {
  const AppRadii._();

  static const double card = 20;
  static const double control = 16;
}

class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

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

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.muted,
      surfaceContainerHighest: AppColors.fill,
      outlineVariant: AppColors.border,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
    navigationBarTheme: _navigationBarTheme(
      background: AppColors.surface,
      selected: AppColors.primary,
      unselected: AppColors.muted,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      onPrimary: Color(0xFF000000),
      secondary: Color(0xFFEDEDED),
      surface: Color(0xFF1B1B1B),
      onSurface: Color(0xFFEDEDED),
      onSurfaceVariant: Color(0xFFB0B0B2),
      surfaceContainerHighest: Color(0xFF2A2A2C),
      outlineVariant: Color(0xFF3A3A3C),
      error: Color(0xFFFFB4AB),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    navigationBarTheme: _navigationBarTheme(
      background: const Color(0xFF1B1B1B),
      selected: const Color(0xFFFFFFFF),
      unselected: const Color(0xFFB0B0B2),
    ),
  );
}
