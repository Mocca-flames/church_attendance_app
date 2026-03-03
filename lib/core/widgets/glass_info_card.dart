// lib/core/widgets/glass_info_card.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'glass_container.dart';

/// A glass-style info card for displaying contact/attendance details on screens.
/// 
/// Perfect for:
/// - Contact information displays
/// - Attendance statistics
/// - Quick info summaries
/// - Dashboard metric cards
/// 
/// Example usage:
/// ```dart
/// GlassInfoCard(
///   title: 'John Doe',
///   subtitle: 'Member since 2023',
///   leading: Icon(Icons.person, color: AppColors.cyan500),
///   trailing: Chip(label: Text('Active')),
///   onTap: () => showContactDetails(),
/// )
/// ```
class GlassInfoCard extends StatelessWidget {
  /// Main title text (typically name or primary value)
  final String title;

  /// Optional subtitle text (e.g., role, date, status)
  final String? subtitle;

  /// Optional leading icon or widget
  final Widget? leading;

  /// Optional trailing action (icon button, chip, badge)
  final Widget? trailing;

  /// Optional tap handler
  final VoidCallback? onTap;

  /// Optional long press handler
  final VoidCallback? onLongPress;

  /// Border radius (default: 16)
  final double borderRadius;

  /// Padding inside the card (default: EdgeInsets.all(16))
  final EdgeInsetsGeometry padding;

  /// Margin outside the card
  final EdgeInsetsGeometry? margin;

  /// Custom title style (uses AppTypography.bodyLarge by default)
  final TextStyle? titleStyle;

  /// Custom subtitle style (uses AppTypography.bodyMedium by default)
  final TextStyle? subtitleStyle;

  /// Optional semantic label for accessibility
  final String? semanticLabel;

  /// Optional background blur amount
  final double blur;

  /// Optional background opacity
  final double opacity;

  /// Optional border opacity
  final double borderOpacity;

  /// Whether to show a subtle highlight when tapped
  final bool enableRipple;

  /// Optional icon background color (uses theme by default)
  final Color? iconBackgroundColor;

  /// Optional custom icon size
  final double iconSize;

  const GlassInfoCard({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.titleStyle,
    this.subtitleStyle,
    this.semanticLabel,
    this.blur = 8,
    this.opacity = 0.12,
    this.borderOpacity = 0.15,
    this.enableRipple = true,
    this.iconBackgroundColor,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Row(
      children: [
        // Leading icon/widget
        if (leading != null) ...[
          _buildIconContainer(isDark, colorScheme),
          const SizedBox(width: 16),
        ],

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: titleStyle ?? AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.neutral800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: subtitleStyle ?? AppTypography.bodyMedium.copyWith(
                    color: isDark 
                        ? AppColors.darkTextMuted 
                        : AppColors.neutral600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Trailing action
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );

    return GlassContainer(
      opacity: opacity,
      blur: blur,
      borderRadius: borderRadius,
      borderOpacity: borderOpacity,
      padding: padding,
      margin: margin,
      child: enableRipple && onTap != null
          ? _buildRippleWrapper(content, isDark, colorScheme)
          : content,
    );
  }

  Widget _buildIconContainer(bool isDark, ColorScheme colorScheme) {
    final bgColor = iconBackgroundColor ?? (isDark
        ? AppColors.cyan900.withValues(alpha: 0.4)
        : AppColors.cyan100.withValues(alpha: 0.6));

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            size: iconSize,
            color: isDark ? AppColors.cyan400 : AppColors.cyan700,
          ),
          child: leading!,
        ),
      ),
    );
  }

  Widget _buildRippleWrapper(Widget child, bool isDark, ColorScheme colorScheme) {
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

  /// Create a metric-style info card with a large value and label
  factory GlassInfoCard.metric({
    required String value,
    required String label,
    Key? key,
    Widget? icon,
    Color? valueColor,
    Color? iconBackgroundColor,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassInfoCard(
      key: key,
      title: value,
      subtitle: label,
      leading: icon,
      titleStyle: AppTypography.h2.copyWith(
        fontWeight: FontWeight.bold,
        color: valueColor,
      ),
      subtitleStyle: AppTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w500,
      ),
      iconBackgroundColor: iconBackgroundColor,
      onTap: onTap,
      margin: margin,
    );
  }

  /// Create a compact row-style info card
  factory GlassInfoCard.compact({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassInfoCard(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: margin,
      blur: 6,
      opacity: 0.10,
    );
  }

  /// Create a status card with color-coded indicator
  factory GlassInfoCard.status({
    required String title,
    required bool isActive,
    String? subtitle,
    Widget? leading,
    VoidCallback? onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassInfoCard(
      title: title,
      subtitle: subtitle ?? (isActive ? 'Active' : 'Inactive'),
      leading: leading,
      trailing: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: isActive ? AppColors.success : AppColors.neutral400,
          shape: BoxShape.circle,
        ),
      ),
      onTap: onTap,
      margin: margin,
      borderOpacity: isActive ? 0.3 : 0.15,
    );
  }
}
