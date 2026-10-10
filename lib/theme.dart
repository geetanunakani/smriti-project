import 'package:flutter/material.dart';

/// Palette pulled from the SMRITI pitch deck.
class SmritiColors {
  static const plum = Color(0xFF3D0F2B);
  static const plumDeep = Color(0xFF26081A);
  static const rose = Color(0xFFA93A63);
  static const roseLight = Color(0xFFD9A9BE);
  static const mauve = Color(0xFFB78098);
  static const petal = Color(0xFFE8CEDA);
  static const blush = Color(0xFFF6E9EE);
  static const ink = Color(0xFF6E5060);
}

ThemeData buildSmritiTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: SmritiColors.rose,
    primary: SmritiColors.rose,
    secondary: SmritiColors.plum,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SmritiColors.plum,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: SmritiColors.rose,
    ),
  );
}