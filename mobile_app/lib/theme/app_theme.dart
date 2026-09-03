import 'package:flutter/material.dart';

/// A calm, eye-friendly theme for Yarmouk Water Pro.
/// Uses a soft blue-grey background (avoiding harsh pure white) and a
/// deep, comfortable blue as the primary color with readable slate text.
class AppTheme {
  static const Color primary = Color(0xFF1E4D8C);
  static const Color primaryDark = Color(0xFF163A6B);
  static const Color background = Color(0xFFF1F5FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF22324A);
  static const Color textSecondary = Color(0xFF5C6B82);
  static const Color divider = Color(0xFFE2E8F1);
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFD79A1E);
  static const Color danger = Color(0xFFD9534F);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        primaryColor: primary,
        scaffoldBackgroundColor: background,
        canvasColor: background,
        cardColor: surface,
        dividerColor: divider,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: primaryDark,
          surface: surface,
          onPrimary: Colors.white,
          onSurface: textPrimary,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
          hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(
              color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(
              color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.45),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 14, height: 1.4),
          labelLarge: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: textSecondary, size: 22),
        listTileTheme: const ListTileThemeData(
          iconColor: primary,
          titleTextStyle: TextStyle(color: textPrimary, fontSize: 16),
          subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 13),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
}
