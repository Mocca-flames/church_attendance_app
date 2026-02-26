// lib/core/widgets/device_info_card.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';


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
    this.trailing,super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral200.withValues(alpha:0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: (isMonospace ? AppTypography.mono : AppTypography.bodyLarge).copyWith(
                    color: valueColor ?? AppColors.neutral800,
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