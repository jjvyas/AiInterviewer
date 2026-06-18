import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Static theme state tracked globally
  static bool isDarkState = true;

  // Dark Mode Palette Colors (Glassmorphic semi-translucent)
  static const Color darkCanvas = Color(0xFF09090C); // Deep space dark canvas
  static const Color darkPanel = Color(0x6616161A);  // Translucent panel (40% opacity)
  static const Color darkCard = Color(0x4D222228);   // Translucent card (30% opacity)
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF8F909A);
  static const Color darkTealAccent = Color(0xFF00ADB5);
  static const Color darkGoldAccent = Color(0xFFE2B659);
  static const Color darkBorder = Color(0x1AFFFFFF);  // Low opacity white border (10%)

  // Light Mode Palette Colors (Glassmorphic semi-translucent)
  static const Color lightCanvas = Color(0xFFF1F5F9);
  static const Color lightPanel = Color(0x99EBF0F6);  // Translucent light panel (60% opacity)
  static const Color lightCard = Color(0xCCFFFFFF);   // Translucent light card (80% opacity)
  static const Color lightText = Color(0xFF1E1E24);
  static const Color lightTextMuted = Color(0xFF6C757D);
  static const Color lightTealAccent = Color(0xFF008080);
  static const Color lightGoldAccent = Color(0xFFB8860B);
  static const Color lightBorder = Color(0x1A000000);  // Low opacity black border (10%)

  // Dynamic getters to resolve theme colors for views
  static Color get canvasBg => isDarkState ? darkCanvas : lightCanvas;
  static Color get panelBg => isDarkState ? darkPanel : lightPanel;
  static Color get cardBg => isDarkState ? darkCard : lightCard;
  static Color get textDark => isDarkState ? darkText : lightText;
  static Color get accentHighlight => isDarkState ? darkTealAccent : lightTealAccent;
  static Color get goldAccent => isDarkState ? darkGoldAccent : lightGoldAccent;
  static Color get borderColor => isDarkState ? darkBorder : lightBorder;

  // Modern Dark Theme definition
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Let Scaffold stack container background show
      primaryColor: darkTealAccent,
      colorScheme: const ColorScheme.dark(
        primary: darkTealAccent,
        secondary: darkCard,
        surface: darkPanel,
        onPrimary: Colors.white,
        onSecondary: darkText,
        onSurface: darkText,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: darkText,
        displayColor: darkText,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkPanel.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkTealAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkTextMuted),
        hintStyle: const TextStyle(color: darkTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTealAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: darkBorder, width: 1.0),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkTealAccent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Modern Light Theme definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      primaryColor: lightTealAccent,
      colorScheme: const ColorScheme.light(
        primary: lightTealAccent,
        secondary: lightCard,
        surface: lightPanel,
        onPrimary: Colors.white,
        onSecondary: lightText,
        onSurface: lightText,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: lightTealAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: lightTextMuted),
        hintStyle: const TextStyle(color: lightTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightTealAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: lightBorder, width: 1.0),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightTealAccent,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
