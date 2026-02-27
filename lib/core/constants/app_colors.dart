// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Centralized color system for the application.
/// 
/// Design principles:
/// - Light mode: Soft, approachable with warm grays and vibrant accents
/// - Dark mode: Windows 11 inspired - neutral grays, layered depth, high contrast
class AppColors {
  AppColors._();

  // ═══════════════════════════════════════════════════
  // LIGHT THEME - BACKGROUND SYSTEM
  // ═══════════════════════════════════════════════════
  
  /// Primary background - Soft cool gray with subtle blue tint
  static const Color backgroundPrimary = Color(0xFFF8F9FC);
  
  /// Secondary background - Slightly warmer for contrast areas
  static const Color backgroundSecondary = Color(0xFFF0F4F8);
  
  /// Elevated surface - Cards, sheets
  static const Color surface = Colors.white;
  
  // ═══════════════════════════════════════════════════
  // DARK THEME - BACKGROUND SYSTEM (Windows 11 Style)
  // ═══════════════════════════════════════════════════

  /// Base canvas — true dark but not pitch black (Win11 uses #202020)
  static const Color darkBackgroundPrimary = Color(0xFF202020);

  /// Slightly elevated panels, sidebars, drawers
  static const Color darkBackgroundSecondary = Color(0xFF2C2C2C);

  /// Card/sheet surfaces
  static const Color darkSurface = Color(0xFF2C2C2C);

  /// Elevated cards, dialogs, dropdowns (Fluent "layer" system)
  static const Color darkSurfaceElevated = Color(0xFF383838);

  /// Highest elevation — tooltips, context menus
  static const Color darkSurfaceOverlay = Color(0xFF404040);

  // ═══════════════════════════════════════════════════
  // PRIMARY PALETTE (Consistent across themes)
  // ═══════════════════════════════════════════════════
  
  /// Primary - Vibrant cyan-blue (tech-forward, friendly)
  static const Color primary = Color(0xFF0EA5E9);
  static const Color primaryDark = Color(0xFF0284C7);
  
  /// Light theme containers
  static const Color primaryContainer = Color(0xFFE0F2FE);
  static const Color onPrimaryContainer = Color(0xFF0C4A6E);
  
  /// Dark theme containers (darker base, same accent)
  static const Color darkPrimaryContainer = Color(0xFF0C4A6E);
  static const Color darkOnPrimaryContainer = Color(0xFFE0F2FE);

  static const Color onPrimary = Colors.white;

  // ═══════════════════════════════════════════════════
  // SECONDARY PALETTE (Consistent across themes)
  // ═══════════════════════════════════════════════════
  
  /// Secondary - Coral/salmon (friendly, approachable)
  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryDark = Color(0xFFEA580C);
  
  /// Light theme containers
  static const Color secondaryContainer = Color(0xFFFFEDD5);
  static const Color onSecondaryContainer = Color(0xFF7C2D12);
  
  /// Dark theme containers
  static const Color darkSecondaryContainer = Color(0xFF7C2D12);
  static const Color darkOnSecondaryContainer = Color(0xFFFFEDD5);

  static const Color onSecondary = Colors.white;

  // ═══════════════════════════════════════════════════
  // ACCENT PALETTE (Fun surprises - consistent)
  // ═══════════════════════════════════════════════════
  
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentMint = Color(0xFF10B981);
  static const Color accentRose = Color(0xFFF43F5E);
  static const Color accentAmber = Color(0xFFF59E0B);

  // ═══════════════════════════════════════════════════
  // SEMANTIC COLORS (Status indicators)
  // ═══════════════════════════════════════════════════
  
  // Success
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color successDark = Color(0xFF14532D); // Dark container
  
  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF7F1D1D); // Dark container
  static const Color errorBorderLight = Color(0xFFFCA5A5);
  static const Color errorBorderDark = Color(0xFFF87171);
  
  // Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF78350F); // Dark container
  
  // Info
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E3A8A); // Dark container

  // ═══════════════════════════════════════════════════
  // TEXT COLORS
  // ═══════════════════════════════════════════════════
  
  // Light theme text (warm grays)
  static const Color neutral900 = Color(0xFF111827);  // Headlines
  static const Color neutral800 = Color(0xFF1F2937);  // Primary text
  static const Color neutral700 = Color(0xFF374151);  // Secondary text
  static const Color neutral600 = Color(0xFF4B5563);  // Body text
  static const Color neutral500 = Color(0xFF6B7280);  // Muted
  static const Color neutral400 = Color(0xFF9CA3AF);  // Disabled
  static const Color neutral300 = Color(0xFFD1D5DB);  // Borders
  static const Color neutral200 = Color(0xFFE5E7EB);  // Dividers
  static const Color neutral100 = Color(0xFFF3F4F6);  // Subtle backgrounds
  static const Color neutral50  = Color(0xFFF9FAFB);  // Lightest

  // Dark theme text (cool grays for contrast against dark bg)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC8C8C8);
  static const Color darkTextMuted = Color(0xFF8A8A8A);

  // ═══════════════════════════════════════════════════
  // BORDERS & DIVIDERS
  // ═══════════════════════════════════════════════════
  
  static const Color borderLight = Color(0xFFD1D5DB); // neutral300
  static const Color borderDark = Color(0xFF404040);
  static const Color dividerLight = Color(0xFFE5E7EB); // neutral200
  static const Color dividerDark = Color(0xFF505050);

  // ═══════════════════════════════════════════════════
  // INPUT COLORS
  // ═══════════════════════════════════════════════════
  
  static const Color inputBackgroundLight = Color(0xFFF9FAFB); // neutral50
  static const Color inputBackgroundDark = Color(0xFF1C1C1C);
  static const Color inputFocusedDark = Color(0xFF0EA5E9); // primary

  // ═══════════════════════════════════════════════════
  // DYNAMIC COMPONENTS (Context-aware)
  // ═══════════════════════════════════════════════════
  
  static const Color deviceActive = Color(0xFF10B981);
  static const Color charging = Color(0xFF22C55E);
  static const Color chargingSlow = Color(0xFFF59E0B);
  static const Color deviceError = Color(0xFFEF4444);
  
  static const List<Color> progressGradient = [
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
  ];
  
  static const Color batteryGood = Color(0xFF22C55E);
  static const Color batteryMedium = Color(0xFFF59E0B);
  static const Color batteryLow = Color(0xFFEF4444);

  // ═══════════════════════════════════════════════════
  // LEGACY ALIASES (For backward compatibility)
  // ═══════════════════════════════════════════════════

  static const Color textSecondary = neutral600;
  static const Color scenariosColor = accentPurple;

  // ═══════════════════════════════════════════════════
  // LIGHT THEME GRADIENTS (Modern light grey + Cyan)
  // ═══════════════════════════════════════════════════

  /// Primary background gradient - Soft white to subtle cyan tint
  /// More distinct colors for visible gradient effect
  static const List<Color> backgroundGradientLight = [
    Color(0xFFFFFFFF), // Pure white at top
    Color(0xFFECFDF5), // Very subtle mint-cyan tint at bottom
  ];

  /// Header/AppBar gradient - Light grey to soft cyan
  static const List<Color> headerGradientLight = [
    Color(0xFFF1F5F9), // Slate 100
    Color(0xFFE0F2FE), // Cyan 100
  ];

  /// Card/Surface gradient - White to very subtle cyan
  static const List<Color> surfaceGradientLight = [
    Colors.white,
    Color(0xFFF8FAFC), // Very subtle cyan-grey
  ];

  /// Accent gradient - Cyan to Turquoise (for highlights)
  static const List<Color> accentGradientLight = [
    Color(0xFF06B6D4), // Cyan 500
    Color(0xFF14B8A6), // Teal 500
  ];

  /// Hero section gradient - Light grey with cyan wash
  static const List<Color> heroGradientLight = [
    Color(0xFFF8FAFC),
    Color(0xFFE0F2FE),
    Color(0xFFBAE6FD), // Cyan 200
  ];

  // ═══════════════════════════════════════════════════
  // DARK THEME GRADIENTS (Windows 11 inspired + Cyan accent)
  // ═══════════════════════════════════════════════════

  /// Primary background gradient - Win11 dark with cyan depth
  static const List<Color> backgroundGradientDark = [
    Color(0xFF202020), // Win11 base
    Color(0xFF1A2024), // Subtle cyan-grey depth
  ];

  /// Header/AppBar gradient - Layered dark with cyan tint
  static const List<Color> headerGradientDark = [
    Color(0xFF202020),
    Color(0xFF1C2C35), // Deep cyan-grey
  ];

  /// Surface elevation gradient - For cards/dialogs
  static const List<Color> surfaceGradientDark = [
    Color(0xFF2C2C2C), // Surface
    Color(0xFF2A3439), // Slight cyan tint
  ];

  /// High elevation gradient - Tooltips, menus
  static const List<Color> elevatedGradientDark = [
    Color(0xFF383838),
    Color(0xFF354046), // Cyan-grey elevation
  ];

  /// Accent gradient - Electric cyan to turquoise (dark mode pop)
  static const List<Color> accentGradientDark = [
    Color(0xFF22D3EE), // Cyan 400 (brighter for dark)
    Color(0xFF2DD4BF), // Teal 400
  ];

  /// Hero/Feature gradient - Deep dark to cyan glow
  static const List<Color> heroGradientDark = [
    Color(0xFF202020),
    Color(0xFF0F172A), // Slate 900
    Color(0xFF164E63), // Cyan 900
  ];

  /// Glassmorphism gradient - For modern overlays
  static const List<Color> glassGradientDark = [
    Color(0xFF2C2C2C),
    Color(0xFF1E3A4A), // Transparent cyan feel
  ];

  // ═══════════════════════════════════════════════════
  // CYAN COLOR SCALE (Consistent across themes)
  // ═══════════════════════════════════════════════════

  static const Color cyan50 = Color(0xFFECFEFF);
  static const Color cyan100 = Color(0xFFCFFAFE);
  static const Color cyan200 = Color(0xFFA5F3FC);
  static const Color cyan300 = Color(0xFF67E8F9);
  static const Color cyan400 = Color(0xFF22D3EE);
  static const Color cyan500 = Color(0xFF06B6D4);
  static const Color cyan600 = Color(0xFF0891B2);
  static const Color cyan700 = Color(0xFF0E7490);
  static const Color cyan800 = Color(0xFF155E75);
  static const Color cyan900 = Color(0xFF164E63);

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal900 = Color(0xFF134E4A);
}