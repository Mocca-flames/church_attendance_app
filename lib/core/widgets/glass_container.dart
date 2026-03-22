// lib/core/widgets/glass_container.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Base glassmorphism container widget that provides a frosted glass effect.
/// 
/// Works seamlessly with the app's dynamic gradient background by using
/// semi-transparent backgrounds with backdrop blur.
/// 
/// Example usage:
/// ```dart
/// GlassContainer(
///   opacity: 0.15,
///   blur: 12,
///   borderRadius: 20,
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Glass content'),
///   ),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  /// The child widget to display inside the glass container
  final Widget child;

  /// Background opacity (0.0 to 1.0)
  /// Light mode: typically 0.10 - 0.20
  /// Dark mode: typically 0.15 - 0.30
  final double opacity;

  /// Backdrop blur amount (higher = more blur)
  final double blur;

  /// Border radius for rounded corners
  final double borderRadius;

  /// Border opacity (0.0 to 1.0)
  final double borderOpacity;

  /// Optional custom border color (uses theme-aware default if null)
  final Color? borderColor;

  /// Optional custom background color (uses theme-aware default if null)
  final Color? backgroundColor;

  /// Optional gradient for the background (overrides backgroundColor if set)
  final Gradient? gradient;

  /// Optional shadow
  final List<BoxShadow>? boxShadow;

  /// Padding inside the container
  final EdgeInsetsGeometry? padding;

  /// Margin outside the container
  final EdgeInsetsGeometry? margin;

  /// Minimum width constraint
  final double? minWidth;

  /// Maximum width constraint
  final double? maxWidth;

  /// Minimum height constraint
  final double? minHeight;

  /// Maximum height constraint
  final double? maxHeight;

  /// Alignment for the child
  final AlignmentGeometry? alignment;

  const GlassContainer({
    required this.child,
    super.key,
    this.opacity = 0.15,
    this.blur = 12.0,
    this.borderRadius = 20.0,
    this.borderOpacity = 0.2,
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.boxShadow,
    this.padding,
    this.margin,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Theme-aware background color
    final bgColor = backgroundColor ?? (isDark 
        ? AppColors.darkSurface.withValues(alpha: opacity)
        : Colors.white.withValues(alpha: opacity));

    // Theme-aware border color
    final border = borderColor ?? (isDark
        ? AppColors.cyan400.withValues(alpha: borderOpacity)
        : AppColors.cyan500.withValues(alpha: borderOpacity));

    // Default glass shadow
    final shadows = boxShadow ?? (isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]);

    return Container(
      margin: margin,
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0,
        maxWidth: maxWidth ?? double.infinity,
        minHeight: minHeight ?? 0,
        maxHeight: maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            alignment: alignment,
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? bgColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: border,
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Pre-defined glass container for info cards with lighter opacity
  factory GlassContainer.info({
    required Widget child,
    Key? key,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
    Widget? trailing,
  }) {
    return GlassContainer(
      key: key,
      opacity: 0.12,
      blur: 8,
      borderRadius: borderRadius ?? 16,
      borderOpacity: 0.15,
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );
  }

  /// Pre-defined glass container for popup dialogs/sheets
  factory GlassContainer.popup({
    required Widget child,
    Key? key,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      key: key,
      opacity: 0.20,
      blur: 16,
      borderRadius: borderRadius ?? 24,
      borderOpacity: 0.25,
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }

  /// Pre-defined glass container with accent glow effect
  factory GlassContainer.accent({
    required Widget child,
    Key? key,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassContainer(
      key: key,
      opacity: 0.18,
      blur: 14,
      borderRadius: borderRadius ?? 20,
      borderOpacity: 0.3,
      padding: padding ?? const EdgeInsets.all(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.cyan500.withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
      child: child,
    );
  }
}
