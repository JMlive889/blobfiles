import 'package:flutter/material.dart';

/// Centralized color palette for blobfiles.
abstract final class AppColors {
  // ── Dark theme ──────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF1A1D24);
  static const Color darkAccent = Color(0xFFE8E7DC);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA0A4AD);
  static const Color darkBorder = Color(0xFF2A2E38);
  /// Dark text on the light cream accent.
  static const Color darkOnAccent = Color(0xFF0F1117);

  // ── Light theme ───────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFF5C5A4E);
  static const Color lightTextPrimary = Color(0xFF1A202C);
  static const Color lightTextSecondary = Color(0xFF4A5568);
  static const Color lightBorder = Color(0xFFE2E8F0);
  /// White text on the dark warm-gray accent.
  static const Color lightOnAccent = Color(0xFFFFFFFF);
}