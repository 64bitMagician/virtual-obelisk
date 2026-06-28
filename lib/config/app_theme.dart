import 'package:flutter/material.dart';

class AppTheme {
  static const Color _seedColor = Color(0xFF6A8E7F);

  static const Color _lightBackground = Color(0xFFF8FAF9);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightOnSurface = Color(0xFF1E2F28);

  static const Color _darkBackground = Color(0xFF181C1A);
  static const Color _darkSurface = Color(0xFF222825);
  static const Color _darkOnSurface = Color(0xFFE2EBE6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        background: _lightBackground,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
      ),

      scaffoldBackgroundColor: _lightBackground,

      textTheme: _textTheme(Colors.black87),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: _lightBackground,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      elevatedButtonTheme: _elevatedButtonThemeData,
      inputDecorationTheme: _inputDecorationTheme(Colors.grey.shade400, _lightSurface),
      cardTheme: _cardTheme(_lightSurface),
    );
  }


  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        background: _darkBackground,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
      ),

      scaffoldBackgroundColor: _darkBackground,

      textTheme: _textTheme(_darkOnSurface),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: _darkBackground,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: _darkOnSurface),
        titleTextStyle: TextStyle(
          color: _darkOnSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      elevatedButtonTheme: _elevatedButtonThemeData,
      inputDecorationTheme: _inputDecorationTheme(Colors.grey.shade700, _darkSurface),
      cardTheme: _cardTheme(_darkSurface),
    );
  }

  static TextTheme _textTheme(Color baseColor) {
    return TextTheme(
      displayLarge: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: baseColor, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: baseColor, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: baseColor, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(color: baseColor, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: baseColor), // Standard text
      bodyMedium: TextStyle(color: baseColor.withOpacity(0.8)), // Subtitles
    );
  }

  static final ElevatedButtonThemeData _elevatedButtonThemeData = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme(Color borderColor, Color fillColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _seedColor, width: 2),
      ),
    );
  }

  static CardTheme _cardTheme(Color color) {
    return CardTheme(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1),
      ),
      margin: const EdgeInsets.all(8),
    );
  }
}