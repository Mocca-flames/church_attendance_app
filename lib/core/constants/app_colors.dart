// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  
  // ═══════════════════════════════════════════════════
  // DYNAMIC BACKGROUND SYSTEM (Not boring white!)
  // ═══════════════════════════════════════════════════
  
  /// Primary background - Soft cool gray with subtle blue tint
  static const Color backgroundPrimary = Color(0xFFF8F9FC);
  
  /// Secondary background - Slightly warmer for contrast areas
  static const Color backgroundSecondary = Color(0xFFF0F4F8);
  
  /// Elevated surface - Cards, sheets
  static const Color surface = Colors.white;
  
  /// Subtle gradient start for dynamic headers
  static const Color gradientStart = Color(0xFFEEF2FF);
  
  /// Subtle gradient end
  static const Color gradientEnd = Color(0xFFF8FAFC);
  
  // ═══════════════════════════════════════════════════
  // PRIMARY PALETTE (Energetic but trustworthy)
  // ═══════════════════════════════════════════════════
  
  /// Primary - Vibrant cyan-blue (tech-forward, friendly)
  static const Color primary = Color(0xFF0EA5E9);
  
  /// Primary container - Soft background for primary elements
  static const Color primaryContainer = Color(0xFFE0F2FE);
  
  /// On primary - White text/icons on primary
  static const Color onPrimary = Colors.white;
  
  /// Primary dark - For hover/pressed states
  static const Color primaryDark = Color(0xFF0284C7);
  
  // ═══════════════════════════════════════════════════
  // SECONDARY PALETTE (Warmth & creativity)
  // ═══════════════════════════════════════════════════
  
  /// Secondary - Coral/salmon (friendly, approachable)
  static const Color secondary = Color(0xFFF97316);
  
  /// Secondary container - Soft peach backgrounds
  static const Color secondaryContainer = Color(0xFFFFEDD5);
  
  /// On secondary - White text
  static const Color onSecondary = Colors.white;
  
  /// Secondary dark - Pressed states
  static const Color secondaryDark = Color(0xFFEA580C);
  
  // ═══════════════════════════════════════════════════
  // ACCENT PALETTE (Fun surprises)
  // ═══════════════════════════════════════════════════
  
  /// Accent 1 - Electric purple (innovation, premium)
  static const Color accentPurple = Color(0xFF8B5CF6);
  
  /// Accent 2 - Mint green (fresh, success)
  static const Color accentMint = Color(0xFF10B981);
  
  /// Accent 3 - Rose pink (attention, playful)
  static const Color accentRose = Color(0xFFF43F5E);
  
  /// Accent 4 - Amber gold (warnings, highlights)
  static const Color accentAmber = Color(0xFFF59E0B);
  
  // ═══════════════════════════════════════════════════
  // SEMANTIC COLORS (Status indicators)
  // ═══════════════════════════════════════════════════
  
  /// Success - Vibrant green (from screenshot checkmarks)
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  
  /// Error - Coral red (from screenshot warnings)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  
  /// Error Border - Softer red for light mode, vibrant for dark mode
  static const Color errorBorderLight = Color(0xFFFCA5A5);
  static const Color errorBorderDark = Color(0xFFF87171);
  
  /// Warning - Warm amber
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  
  /// Info - Cool blue
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  
  // ═══════════════════════════════════════════════════
  // NEUTRAL SCALE (Warm grays, not cold)
  // ═══════════════════════════════════════════════════
  
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
  
  // ═══════════════════════════════════════════════════
  // DARK THEME — Windows 11 Style
  // Clean neutral greys, Fluent Design-inspired depth
  // ═══════════════════════════════════════════════════

  /// Base canvas — true dark but not pitch black (Win11 uses #202020)
  static const Color _darkBackgroundPrimary   = Color(0xFF202020);

  /// Slightly elevated panels, sidebars, drawers
  static const Color _darkBackgroundSecondary = Color(0xFF2C2C2C);

  /// Card/sheet surfaces
  static const Color _darkSurface            = Color(0xFF2C2C2C);

  /// Elevated cards, dialogs, dropdowns (Fluent "layer" system)
  static const Color _darkSurfaceElevated    = Color(0xFF383838);

  /// Highest elevation — tooltips, context menus
  static const Color _darkSurfaceOverlay     = Color(0xFF404040);

  // Dark text colors
  /// Primary text — pure white for crisp legibility
  static const Color _darkTextPrimary        = Color(0xFFFFFFFF);

  /// Secondary text — softened for hierarchy
  static const Color _darkTextSecondary      = Color(0xFFC8C8C8);

  /// Muted / placeholder / disabled
  static const Color _darkTextMuted          = Color(0xFF8A8A8A);

  // Dark border / divider
  /// Subtle border — barely-there separation (Fluent stroke style)
  static const Color _darkBorder             = Color(0xFF404040);

  /// Divider lines between sections
  static const Color _darkDivider            = Color(0xFF505050);

  // Dark input
  /// Input fields — slightly recessed from surface
  static const Color _darkInputBackground    = Color(0xFF1C1C1C);

  /// Input focused ring — uses primary accent (cyan-blue)
  static const Color _darkInputFocused       = Color(0xFF0EA5E9);

  // Dark accent — Windows 11 default accent is blue; we keep your cyan
  static const Color _darkAccentPrimary      = Color(0xFF0EA5E9);
  static const Color _darkAccentContainer    = Color(0xFF1A3F52); // muted container
  
  // ═══════════════════════════════════════════════════
  // DARK THEME PUBLIC ACCESSORS
  // ═══════════════════════════════════════════════════

  static const Color darkBackgroundPrimary   = _darkBackgroundPrimary;
  static const Color darkBackgroundSecondary = _darkBackgroundSecondary;
  static const Color darkSurface             = _darkSurface;
  static const Color darkSurfaceElevated     = _darkSurfaceElevated;
  static const Color darkSurfaceOverlay      = _darkSurfaceOverlay;
  static const Color darkTextPrimary         = _darkTextPrimary;
  static const Color darkTextSecondary       = _darkTextSecondary;
  static const Color darkTextMuted           = _darkTextMuted;
  static const Color darkBorder              = _darkBorder;
  static const Color darkDivider             = _darkDivider;
  static const Color darkInputBackground     = _darkInputBackground;
  static const Color darkInputFocused        = _darkInputFocused;
  static const Color darkAccentPrimary       = _darkAccentPrimary;
  static const Color darkAccentContainer     = _darkAccentContainer;

  // ═══════════════════════════════════════════════════
  // DYNAMIC COMPONENTS (Context-aware colors)
  // ═══════════════════════════════════════════════════
  
  /// Device status: Active/connected
  static const Color deviceActive = Color(0xFF10B981);
  
  /// Device status: Charging (from screenshot)
  static const Color charging = Color(0xFF22C55E);
  
  /// Device status: Warning (slow charging from screenshot)
  static const Color chargingSlow = Color(0xFFF59E0B);
  
  /// Device status: Error/Disconnected
  static const Color deviceError = Color(0xFFEF4444);
  
  /// Progress indicators - Gradient stops
  static const List<Color> progressGradient = [
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
  ];
  
  /// Battery good (from screenshot 100%)
  static const Color batteryGood = Color(0xFF22C55E);
  
  /// Battery medium
  static const Color batteryMedium = Color(0xFFF59E0B);
  
  /// Battery low
  static const Color batteryLow = Color(0xFFEF4444);

  // ═══════════════════════════════════════════════════
  // LEGACY/ALIAS COLORS (For backward compatibility)
  // ═══════════════════════════════════════════════════

  /// Alias for neutral600 - Secondary text color
  static const Color textSecondary = neutral600;

  /// Custom color for scenarios feature
  static const Color scenariosColor = accentPurple;
}