import 'package:flutter/material.dart';

class AppTheme {
  static const ink = Color(0xFF1D2B45);
  static const blue = Color(0xFF2F80ED);
  static const navy = Color(0xFF14365D);
  static const cyan = Color(0xFF48A6C6);
  static const lime = Color(0xFF35B96F);
  static const rose = Color(0xFFDC4C45);
  static const amber = Color(0xFFF0BC42);
  static const surface = Color(0xFFF3F7FA);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: blue,
      primary: blue,
      secondary: cyan,
      tertiary: lime,
      surface: surface,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.94),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
        ),
        shadowColor: ink.withValues(alpha: 0.12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.94),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ink.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rose),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: blue.withValues(alpha: 0.24)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: navy,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: navy,
        textColor: ink,
        selectedColor: blue,
        selectedTileColor: blue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
