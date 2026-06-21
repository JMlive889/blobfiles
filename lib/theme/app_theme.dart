import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static const double borderRadius = 8;

  static BorderRadius get borderRadiusAll => BorderRadius.circular(borderRadius);

  static RoundedRectangleBorder get shapeBorder =>
      RoundedRectangleBorder(borderRadius: borderRadiusAll);

  static const EdgeInsets elevatedButtonPadding =
      EdgeInsets.symmetric(horizontal: 36, vertical: 22);

  static const EdgeInsets outlinedButtonPadding =
      EdgeInsets.symmetric(horizontal: 28, vertical: 20);

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        accent: AppColors.darkAccent,
        onAccent: AppColors.darkOnAccent,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        border: AppColors.darkBorder,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        accent: AppColors.lightAccent,
        onAccent: AppColors.lightOnAccent,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        border: AppColors.lightBorder,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color accent,
    required Color onAccent,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      outline: border,
      error: brightness == Brightness.dark
          ? const Color(0xFFCF6679)
          : const Color(0xFFB00020),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      dividerColor: border,
      textTheme: _textTheme(
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        accent: accent,
        onAccent: onAccent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          padding: elevatedButtonPadding,
          shape: shapeBorder,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: accent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: accent,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: shapeBorder.copyWith(
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          backgroundColor: surface,
          side: BorderSide(color: accent, width: 1.5),
          padding: outlinedButtonPadding,
          shape: shapeBorder,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: borderRadiusAll,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusAll,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusAll,
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
    );
  }

  static TextTheme _textTheme({
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
    required Color onAccent,
  }) {
    final headlineStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: accent,
    );

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: accent,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: accent,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: accent,
        letterSpacing: -0.25,
      ),
      headlineLarge: headlineStyle.copyWith(fontSize: 28),
      headlineMedium: headlineStyle.copyWith(fontSize: 24),
      headlineSmall: headlineStyle.copyWith(fontSize: 20),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: accent,
        height: 1.5,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: accent,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: textPrimary,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onAccent,
      ),
    );
  }
}