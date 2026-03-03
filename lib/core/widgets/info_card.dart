// lib/core/widgets/device_info_card.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'glass_container.dart';

/// A device info card with glassmorphism styling.
/// 
/// Displays a label-value pair with optional trailing widget.
/// Perfect for showing device information, contact details, and
/// other key-value pairs.
/// 
/// Example usage:
/// ```dart
/// DeviceInfoCard(
///   label: 'Device ID',
///   value: 'DEV-12345',
///   isMonospace: true,
///   trailing: IconButton(
///     icon: Icon(Icons.copy),
///     onPressed: () => copyToClipboard(),
///   ),
/// )
/// ```
class DeviceInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isMonospace;
  final Color? valueColor;
  final Widget? trailing;

  const DeviceInfoCard({
    required this.label,
    required this.value,
    this.isMonospace = false,
    this.valueColor,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      opacity: isDark ? 0.15 : 0.10,
      blur: 8,
      borderRadius: 12,
      borderOpacity: 0.15,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: (isMonospace 
                          ? AppTypography.mono 
                          : AppTypography.bodyLarge)
                      .copyWith(
                    color: valueColor ?? (isDark 
                        ? Colors.white 
                        : AppColors.neutral800),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
