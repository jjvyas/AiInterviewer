import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Static theme state tracked globally
  static bool isDarkState = true;

  // Dark Mode Palette Colors (Glassmorphic semi-translucent)
  static const Color darkCanvas = Color(0xFF07051A); // Deep indigo canvas
  static const Color darkPanel = Color(0x260F0D25);  // Translucent panel (15% opacity space navy)
  static const Color darkCard = Color(0x3D1A163B);   // Translucent card (24% opacity frosted indigo)
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextMuted = Color(0xFF9EA0B6);
  static const Color darkTealAccent = Color(0xFF00F0FF); // Electric Blue accent
  static const Color darkGoldAccent = Color(0xFFBD00FF); // Neon Purple accent
  static const Color darkBorder = Color(0x2B00F0FF);  // Translucent electric blue border (17% opacity)

  // Light Mode Palette Colors (Glassmorphic semi-translucent)
  static const Color lightCanvas = Color(0xFFF8FAFC);
  static const Color lightPanel = Color(0x7CE2E8F0);  // Translucent light panel
  static const Color lightCard = Color(0xCCFFFFFF);   // Translucent white card
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTealAccent = Color(0xFF0052FF); // Premium corporate blue
  static const Color lightGoldAccent = Color(0xFF8B00FF); // Purple accent
  static const Color lightBorder = Color(0x1A0052FF);  // Low opacity blue border

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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkPanel.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkTealAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: darkTextMuted),
        hintStyle: const TextStyle(color: darkTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkTealAccent,
          foregroundColor: Colors.black, // Dark text on bright electric blue looks extremely sharp
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
