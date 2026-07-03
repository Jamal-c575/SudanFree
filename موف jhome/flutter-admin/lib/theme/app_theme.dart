// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF10B981); // أخضر زمردي
  static const Color secondary = Color(0xFFA78BFA); // بنفسجي
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkSurfaceAlt = Color(0xFF1E293B);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
        fontFamily: 'Cairo',
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
          primary: primary,
          secondary: secondary,
          surface: darkSurface,
        ),
        scaffoldBackgroundColor: darkSurface,
        cardColor: darkSurfaceAlt,
        fontFamily: 'Cairo',
        appBarTheme: const AppBarTheme(
          backgroundColor: darkSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardTheme(
          color: darkSurfaceAlt,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkSurfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}