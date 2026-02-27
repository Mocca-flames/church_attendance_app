// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_typography.dart';


class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF06B6D4), // Cyan 500
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFCFFAFE), // Cyan 100
        onPrimaryContainer: Color(0xFF164E63), // Cyan 900
        secondary: Color(0xFF14B8A6), // Teal 500
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFCCFBF1), // Teal 100
        onSecondaryContainer: Color(0xFF134E4A), // Teal 900
        tertiary: Color(0xFF22C55E), // Green 500 - Success
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFDCFCE7), // Green 100
        onTertiaryContainer: Color(0xFF14532D), // Green 900
        surface: Colors.white,
        onSurface: Color(0xFF1F2937),
        surfaceContainerHighest: Color(0xFFF1F5F9),
        onSurfaceVariant: Color(0xFF64748B),
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE2E8F0),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF991B1B),
        shadow: Color(0x1F000000),
        scrim: Color(0x99000000),
      ),

      // Scaffold with gradient background capability
      scaffoldBackgroundColor: AppColors.backgroundGradientLight[0],

      // App Bar with cyan-tinted gradient
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1F2937),
        centerTitle: false,
        titleTextStyle: AppTypography.h3.copyWith(
          color: const Color(0xFF0E7490), // Cyan 700
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Cards with subtle cyan-white gradient
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        // Use Container with gradient in your widget:
        // decoration: BoxDecoration(
        //   gradient: LinearGradient(colors: AppColors.surfaceGradientLight),
        //   borderRadius: BorderRadius.circular(20),
        // ),
      ),

      // Buttons with cyan gradients
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF06B6D4), // Cyan 500
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.button,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFF0891B2); // Cyan 600
            }
            return const Color(0xFF06B6D4);
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF06B6D4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0891B2),
          side: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input with cyan focus
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
      ),

      // Chips with cyan accent
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF1F5F9),
        selectedColor: const Color(0xFFCFFAFE),
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: const Color(0xFF0891B2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Progress with cyan gradient capability
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF06B6D4),
        linearTrackColor: Color(0xFFE2E8F0),
        circularTrackColor: Color(0xFFE2E8F0),
      ),

      // Sliders with cyan
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF06B6D4),
        inactiveTrackColor: const Color(0xFFE2E8F0),
        thumbColor: const Color(0xFF06B6D4),
        overlayColor: const Color(0xFF06B6D4).withValues(alpha: 0.1),
        trackHeight: 4,
      ),

      // Switches with cyan
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF06B6D4);
          }
          return const Color(0xFF94A3B8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFCFFAFE);
          }
          return const Color(0xFFE2E8F0);
        }),
      ),

      // Bottom Navigation with cyan accent
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF06B6D4),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // FAB with mint accent (matching AppColors.accentMint)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF10B981), // Mint
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Dialogs with gradient capability
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Bottom Sheets with cyan tint
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbars with cyan-dark
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF164E63),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF22D3EE), // Cyan 400 (brighter for dark)
        onPrimary: Color(0xFF082F49),
        primaryContainer: Color(0xFF164E63), // Cyan 900
        onPrimaryContainer: Color(0xFFCFFAFE),
        secondary: Color(0xFF2DD4BF), // Teal 400
        onSecondary: Color(0xFF042F2E),
        secondaryContainer: Color(0xFF134E4A), // Teal 900
        onSecondaryContainer: Color(0xFFCCFBF1),
        tertiary: Color(0xFF4ADE80), // Green 400 - Success (brighter for dark)
        onTertiary: Color(0xFF052E16),
        tertiaryContainer: Color(0xFF14532D), // Green 900
        onTertiaryContainer: Color(0xFFBBF7D0), // Green 200
        surface: Color(0xFF2C2C2C),
        onSurface: Colors.white,
        surfaceContainerHighest: Color(0xFF383838),
        onSurfaceVariant: Color(0xFFC8C8C8),
        outline: Color(0xFF404040),
        outlineVariant: Color(0xFF505050),
        error: Color(0xFFEF4444),
        onError: Colors.white,
        errorContainer: Color(0xFF7F1D1D),
        onErrorContainer: Color(0xFFFEE2E2),
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
      ),

      // Scaffold with dark cyan-grey gradient
      scaffoldBackgroundColor: AppColors.backgroundGradientDark[0],

      // App Bar with Win11 + cyan depth
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: Color(0xFF22D3EE), // Cyan 400
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // Cards with dark cyan-grey elevation
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      // Buttons with electric cyan
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF06B6D4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.button,
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFF0891B2);
            }
            return const Color(0xFF06B6D4);
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF06B6D4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF22D3EE),
          side: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input with cyan glow
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF404040), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: const Color(0xFF8A8A8A)),
      ),

      // Chips with cyan container
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF383838),
        selectedColor: const Color(0xFF164E63),
        labelStyle: AppTypography.labelMedium.copyWith(color: Colors.white),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: const Color(0xFF22D3EE),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Progress with cyan
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF22D3EE),
        linearTrackColor: Color(0xFF404040),
        circularTrackColor: Color(0xFF404040),
      ),

      // Sliders with cyan
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF22D3EE),
        inactiveTrackColor: const Color(0xFF404040),
        thumbColor: const Color(0xFF22D3EE),
        overlayColor: const Color(0xFF22D3EE).withValues(alpha: 0.1),
        trackHeight: 4,
      ),

      // Switches with cyan
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF22D3EE);
          }
          return const Color(0xFF8A8A8A);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF164E63);
          }
          return const Color(0xFF404040);
        }),
      ),

      // Bottom Navigation with cyan
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        selectedItemColor: Color(0xFF22D3EE),
        unselectedItemColor: Color(0xFF8A8A8A),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // FAB with mint accent (brighter for dark mode)
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF34D399), // Mint 400 (brighter for dark)
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Dialogs with dark cyan-grey
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Bottom Sheets with cyan tint
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      // Snackbars with cyan-dark
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF383838),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}