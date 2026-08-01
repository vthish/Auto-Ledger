import 'package:flutter/material.dart';

class AppTheme {
  // ==================== OLD COLORS (Keep for backward compatibility) ====================
  static const Color policeBlue = Color(0xFF142C5C);
  static const Color policeBlueLight = Color(0xFF1A3A7A);
  static const Color policeBlueDark = Color(0xFF0D1F3D);

  // Old alias for policeBlue (used heavily in old screens)
  static const Color primaryBlack = policeBlue;
  static const Color softBlack = Color(0xFF1F1F1F);

  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundColor = backgroundWhite; // Alias for old screens

  static const Color lightGray = Color(0xFFF4F6F9);
  static const Color borderGray = Color(0xFFE8ECF1);
  static const Color textGray = Color(0xFF6B7280);

  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);

  static const Color inactiveColor = Color(0xFFA0AEC0);

  // ==================== NEW UI ADDITIONS (For updated screens) ====================
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [policeBlue, policeBlueLight],
  );

  // Full ThemeData (keeps old settings + adds new ones)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundWhite,
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.adaptivePlatformDensity,
    colorScheme: const ColorScheme.light(
      primary: policeBlue,
      secondary: policeBlueLight,
      surface: backgroundWhite,
      error: errorRed,
    ),
    // ===== OLD InputDecoration (kept for old screens) =====
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: policeBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      labelStyle: const TextStyle(color: textGray, fontWeight: FontWeight.w600),
    ),
    // ===== OLD Button Themes (kept for old screens) =====
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: policeBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: policeBlue,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}