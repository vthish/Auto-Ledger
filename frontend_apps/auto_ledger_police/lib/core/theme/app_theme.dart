import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlack = Color(0xFF111111);
  static const Color softBlack = Color(0xFF1F1F1F);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF4F4F4);
  static const Color borderGray = Color(0xFFD9D9D9);
  static const Color textGray = Color(0xFF666666);
  static const Color errorRed = Color(0xFFB00020);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundWhite,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlack,
      brightness: Brightness.light,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundWhite,
      foregroundColor: primaryBlack,
      elevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: primaryBlack, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: const BorderSide(color: errorRed, width: 1.4),
      ),
    ),
  );
}