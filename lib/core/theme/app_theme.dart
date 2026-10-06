import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF09090B);
  static const Color surface = Color(0xFF18181B);
  static const Color surfaceElevated = Color(0xFF27272A);
  static const Color primaryAmber = Color(0xFFF59E0B);
  static const Color accentGold = Color(0xFFEAB308);
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textMuted = Color(0xFFA1A1AA);
  static const Color border = Color(0xFF3F3F46);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primaryAmber,
      surface: surface,
      onSurface: textPrimary,
      outline: border,
    ),
    fontFamily: 'Inter',
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
    ),
  );
}
