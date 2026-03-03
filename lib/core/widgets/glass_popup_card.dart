// lib/core/widgets/glass_popup_card.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'glass_container.dart';

/// A glass-style popup card designed for bottom sheets and dialog containers.
/// 
/// Perfect for:
/// - Modal bottom sheets
/// - Dialog content containers
/// - Popup menus
/// - Confirmation dialogs
/// - Quick action sheets
/// 
/// Example usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   backgroundColor: Colors.transparent,
///   builder: (context) => GlassPopupCard(
///     title: 'Contact Details',
///     subtitle: 'View and edit information',
///     showDragHandle: true,
///     child: Column(
///       children: [...],
///     ),
///   ),
/// )
/// ```
class GlassPopupCard extends StatelessWidget {
  /// Main content widget
  final Widget child;

  /// Optional title for the popup
  final String? title;

  /// Optional subtitle/description
  final String? subtitle;

  /// Whether to show the drag handle (default: true for bottom sheets)
  final bool showDragHandle;

  /// Color of the drag handle
  final Color? dragHandleColor;

  /// Border radius (default: 24 for bottom sheet style)
  final double borderRadius;

  /// Padding inside the card
  final EdgeInsetsGeometry padding;

  /// Margin outside the card
  final EdgeInsetsGeometry? margin;

  /// Optional action button in header
  final Widget? headerAction;

  /// Optional close button callback
  final VoidCallback? onClose;

  /// Blur amount for glass effect
  final double blur;

  /// Background opacity
  final double opacity;

  /// Border opacity
  final double borderOpacity;

  /// Maximum height constraint
  final double? maxHeight;

  /// Whether to constrain height
  final bool isScrollable;

  /// Header alignment
  final CrossAxisAlignment headerAlignment;

  /// Custom title style
  final TextStyle? titleStyle;

  /// Custom subtitle style
  final TextStyle? subtitleStyle;

  /// Optional icon shown before title
  final IconData? titleIcon;

  /// Icon color
  final Color? titleIconColor;

  /// Safe area padding at bottom
  final bool useSafeArea;

  const GlassPopupCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.showDragHandle = true,
    this.dragHandleColor,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.headerAction,
    this.onClose,
    this.blur = 16,
    this.opacity = 0.56,
    this.borderOpacity = 0.25,
    this.maxHeight,
    this.isScrollable = true,
    this.headerAlignment = CrossAxisAlignment.start,
    this.titleStyle,
    this.subtitleStyle,
    this.titleIcon,
    this.titleIconColor,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = useSafeArea 
        ? MediaQuery.of(context).padding.bottom 
        : 0.0;

    Widget content = GlassContainer(
      opacity: opacity,
      blur: blur,
      borderRadius: borderRadius,
      borderOpacity: borderOpacity,
      margin: margin ?? const EdgeInsets.only(top: 8, left: 8, right: 8),
      padding: EdgeInsets.zero, // We'll handle padding internally
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          if (showDragHandle)
            _buildDragHandle(isDark),

          // Header
          if (title != null || onClose != null)
            _buildHeader(isDark, colorScheme),

          // Main content
          if (isScrollable && maxHeight != null)
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: padding,
                  child: child,
                ),
              ),
            )
          else
            Padding(
              padding: padding,
              child: child,
            ),

          // Bottom safe area padding
          SizedBox(height: bottomPadding.toDouble()),
        ],
      ),
    );

    if (maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight!),
        child: content,
      );
    }

    return content;
  }

  Widget _buildDragHandle(bool isDark) {
    final handleColor = dragHandleColor ?? (isDark 
        ? AppColors.neutral600 
        : AppColors.neutral300);

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: handleColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
      child: Row(
        children: [
          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: headerAlignment,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (titleIcon != null) ...[
                        Icon(
                          titleIcon,
                          size: 20,
                          color: titleIconColor ?? colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          title!,
                          style: titleStyle ?? AppTypography.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.neutral800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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

          // Header actions
          if (headerAction != null || onClose != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?headerAction,
                if (onClose != null) 
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close,
                      color: isDark 
                          ? AppColors.darkTextMuted 
                          : AppColors.neutral500,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
                          : AppColors.neutral100,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Factory for creating a dialog-style glass card
  factory GlassPopupCard.dialog({
    required Widget child,
    String? title,
    String? subtitle,
    VoidCallback? onClose,
    EdgeInsetsGeometry? padding,
    double? borderRadius,
  }) {
    return GlassPopupCard(
      title: title,
      subtitle: subtitle,
      onClose: onClose,
      showDragHandle: false,
      borderRadius: borderRadius ?? 20,
      padding: padding ?? const EdgeInsets.all(24),
      opacity: 0.22,
      blur: 18,
      child: child,
    );
  }

  /// Factory for creating a compact action sheet
  factory GlassPopupCard.actionSheet({
    required List<Widget> actions,
    String? title,
    String? subtitle,
    VoidCallback? onCancel,
    EdgeInsetsGeometry? margin,
  }) {
    return GlassPopupCard(
      title: title,
      subtitle: subtitle,
      showDragHandle: true,
      margin: margin,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      opacity: 0.18,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...actions,
          if (onCancel != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Factory for creating a confirmation dialog
  factory GlassPopupCard.confirmation({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    IconData? icon,
  }) {
    return GlassPopupCard.dialog(
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 48,
              color: isDestructive ? AppColors.error : AppColors.cyan500,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              if (onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: Text(cancelText ?? 'Cancel'),
                  ),
                ),
              if (onCancel != null)
                const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  style: isDestructive
                      ? FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                        )
                      : null,
                  child: Text(confirmText ?? 'Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Helper function to show a glass bottom sheet
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  bool showDragHandle = true,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  double? maxHeight,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => GlassPopupCard(
      title: title,
      subtitle: subtitle,
      showDragHandle: showDragHandle,
      maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.9,
      isScrollable: true,
      onClose: () => Navigator.of(context).pop(),
      child: child,
    ),
  );
}

/// Helper function to show a glass dialog
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required Widget child,
  String? title,
  String? subtitle,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: GlassPopupCard.dialog(
        title: title,
        subtitle: subtitle,
        onClose: barrierDismissible ? () => Navigator.of(context).pop() : null,
        child: child,
      ),
    ),
  );
}
