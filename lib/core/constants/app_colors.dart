import 'package:flutter/material.dart';

/// Application-wide constants for colors, strings, and dimensions.
/// Centralizes hardcoded values to make them easily maintainable.
abstract final class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryLight = Color(0xFF6AB7FF);
  static const Color primaryDark = Color(0xFF005CB2);

  // Status colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // Neutral colors
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);

  // Action card colors
  static const Color contactsColor = Colors.green;
  static const Color attendanceColor = Colors.blue;
  static const Color scenariosColor = Colors.orange;
  static const Color syncColor = Colors.purple;

  // Error container colors
  static const Color errorBackground = Color(0xFFFFEBEE);
  static const Color errorBorder = Color(0xFFFFCDD2);
  static const Color errorText = Color(0xFFC62828);
}