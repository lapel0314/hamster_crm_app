import 'package:flutter/material.dart';

class HamsterColors {
  static const background = Color(0xFFFFF7E8);
  static const surface = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFFE8B8);
  static const gold = Color(0xFFF7B733);
  static const deepGold = Color(0xFFD98C18);
  static const brown = Color(0xFF4A2C14);
  static const softBrown = Color(0xFF8A5A2B);
  static const line = Color(0xFFE9CFA1);
  static const mint = Color(0xFFB7E4C7);
  static const input = Color(0xFFFFFDF8);
}

ThemeData buildHamsterTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: HamsterColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HamsterColors.gold,
      primary: HamsterColors.gold,
      secondary: HamsterColors.mint,
      surface: HamsterColors.surface,
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
        color: HamsterColors.brown,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: HamsterColors.brown,
      ),
      bodyMedium: TextStyle(fontSize: 14, color: HamsterColors.brown),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HamsterColors.input,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HamsterColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: HamsterColors.line),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: HamsterColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: HamsterColors.line),
      ),
    ),
  );
}
