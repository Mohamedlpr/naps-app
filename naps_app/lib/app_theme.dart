import 'package:flutter/material.dart';

const ink = Color(0xFF1D2822);
const green = Color(0xFF176B4B);
const paper = Color(0xFFF7F7F2);
const muted = Color(0xFF68736C);
const line = Color(0xFFE2E6DF);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme.copyWith(primary: green, surface: Colors.white),
    scaffoldBackgroundColor: paper,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        fontSize: 25,
        height: 1.4,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        height: 1.45,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.65, color: ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.6, color: ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.55, color: muted),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: green, width: 1.5),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
