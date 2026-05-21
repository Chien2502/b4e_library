import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color _primaryBlue = Color(0xFF1565C0);
  static const Color _primaryLightBlue = Color(0xFF1E88E5);
  static const Color _accentColor = Color(0xFF00B0FF);

  // LIGHT THEME
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          primary: _primaryBlue,
          secondary: _primaryLightBlue,
          tertiary: _accentColor,
          surface: Colors.white,
          surfaceContainerLowest: const Color(0xFFF8F9FE),
          onPrimary: Colors.white,
          onSurface: const Color(0xFF1A1C1E),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FE),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFE1E2EC),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1C1E),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF0F1F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );

  // DARK THEME
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          brightness: Brightness.dark,
          primary: const Color(0xFF82AADF),       // Muted blue — readable on dark
          onPrimary: const Color(0xFF00224B),
          secondary: const Color(0xFF90A8C3),
          onSecondary: const Color(0xFF1A2B3C),
          tertiary: const Color(0xFF4FC3F7),
          surface: const Color(0xFF1A1C22),
          surfaceContainerLowest: const Color(0xFF111318),
          onSurface: const Color(0xFFE2E2E6),
          error: const Color(0xFFFF7070),
          onError: const Color(0xFF4A0000),
        ),
        scaffoldBackgroundColor: const Color(0xFF111318),
        cardColor: const Color(0xFF1E2026),
        dividerColor: const Color(0xFF2E3038),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111318),
          foregroundColor: Color(0xFFE2E2E6),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1C1E),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E2026),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E3038), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E3038), width: 0.8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      );
}
