// lib/core/widgets/glass_card.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'glass_container.dart';

/// A general-purpose glass-style card for any content.
/// 
/// Perfect for:
/// - Dashboard cards
/// - Feature highlights
/// - Content containers
/// - Settings items
/// - Menu cards
/// - General UI cards that need glassmorphism styling
/// 
/// Example usage:
/// ```dart
/// GlassCard(
///   child: Column(
///     children: [
///       Text('Title'),
///       Text('Content here...'),
///     ],
///   ),
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// The main content widget
  final Widget child;

  /// Optional header widget (appears at top)
  final Widget? header;

  /// Optional footer widget (appears at bottom)
  final Widget? footer;

  /// Optional card title (simple text alternative to header)
  final String? title;

  /// Optional subtitle
  final String? subtitle;

  /// Optional leading icon (shown with title)
  final IconData? icon;

  /// Icon color
  final Color? iconColor;

  /// Icon background color
  final Color? iconBackgroundColor;

  /// Border radius (default: 20)
  final double borderRadius;

  /// Padding inside the card (default: EdgeInsets.all(20))
  final EdgeInsetsGeometry padding;

  /// Margin outside the card
  final EdgeInsetsGeometry? margin;

  /// Optional tap handler
  final VoidCallback? onTap;

  /// Optional long press handler
  final VoidCallback? onLongPress;

  /// Background blur amount
  final double blur;

  /// Background opacity
  final double opacity;

  /// Border opacity
  final double borderOpacity;

  /// Optional gradient for the background
  final Gradient? gradient;

  /// Whether to add elevation/shadow
  final bool hasShadow;

  /// Content alignment
  final AlignmentGeometry? alignment;

  /// Minimum height
  final double? minHeight;

  /// Maximum height
  final double? maxHeight;

  /// Width constraint
  final double? width;

  const GlassCard({
    required this.child,
    super.key,
    this.header,
    this.footer,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.blur = 12,
    this.opacity = 0.15,
    this.borderOpacity = 0.2,
    this.gradient,
    this.hasShadow = true,
    this.alignment,
    this.minHeight,
    this.maxHeight,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        if (header != null || title != null)
          _buildHeader(isDark, colorScheme),

        if (header != null || title != null)
          const SizedBox(height: 16),

        // Main content
        Flexible(
          child: Align(
            alignment: alignment ?? Alignment.topLeft,
            child: child,
          ),
        ),

        // Footer section
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );

    // Apply height constraints if specified
    if (minHeight != null || maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight ?? 0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: content,
      );
    }

    return GlassContainer(
      opacity: opacity,
      blur: blur,
      borderRadius: borderRadius,
      borderOpacity: borderOpacity,
      gradient: gradient,
      boxShadow: hasShadow ? null : [],
      padding: padding,
      margin: margin,
      minWidth: width ?? 0,
      maxWidth: width ?? double.infinity,
      child: onTap != null
          ? _buildRippleWrapper(content, colorScheme)
          : content,
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    if (header != null) return header!;

    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? (isDark
                  ? AppColors.cyan900.withValues(alpha: 0.4)
                  : AppColors.cyan100.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? (isDark ? AppColors.cyan400 : AppColors.cyan700),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: AppTypography.h4.copyWith(
                    color: isDark ? Colors.white : AppColors.neutral800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark 
                        ? AppColors.darkTextMuted 
                        : AppColors.neutral600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRippleWrapper(Widget child, ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: colorScheme.primary.withValues(alpha: 0.05),
        child: child,
      ),
    );
  }

  /// Create a compact card for lists
  factory GlassCard.compact({
    required Widget child,
    String? title,
    IconData? icon,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassCard(
      title: title,
      icon: icon,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      margin: margin,
      blur: 8,
      opacity: 0.12,
      child: child,
    );
  }

  /// Create an elevated accent card with glow effect
  factory GlassCard.accent({
    required Widget child,
    String? title,
    String? subtitle,
    IconData? icon,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconColor: AppColors.cyan400,
      iconBackgroundColor: AppColors.cyan900.withValues(alpha: 0.3),
      margin: margin,
      opacity: 0.18,
      blur: 14,
      borderOpacity: 0.3,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.cyan500.withValues(alpha: 0.1),
          Colors.transparent,
        ],
      ),
      child: child,
    );
  }

  /// Create a settings-style card with trailing action
  factory GlassCard.settings({
    required String title,
    required Widget trailing, String? subtitle,
    IconData? icon,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassCard(
      title: title,
      subtitle: subtitle,
      icon: icon ?? Icons.settings_outlined,
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blur: 6,
      opacity: 0.10,
      onTap: onTap,
      child: Row(
        children: [
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  /// Create a feature highlight card
  factory GlassCard.feature({
    required String title,
    required String description,
    required IconData icon,
    Color? accentColor,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassCard(
      title: title,
      subtitle: description,
      icon: icon,
      iconColor: accentColor ?? AppColors.cyan400,
      iconBackgroundColor: (accentColor ?? AppColors.cyan500).withValues(alpha: 0.15),
      margin: margin,
      opacity: 0.15,
      blur: 10,
      borderOpacity: 0.25,
      onTap: onTap,
      child: const SizedBox.shrink(),
    );
  }
}
