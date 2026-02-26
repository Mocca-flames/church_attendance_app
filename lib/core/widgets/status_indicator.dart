// lib/core/widgets/status_indicator.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

enum StatusType {
  normal,
  warning,
  error,
  info,
}

class StatusIndicator extends StatelessWidget {
  final String label;
  final StatusType status;
  final bool showIcon;
  final IconData? customIcon;
  
  const StatusIndicator({
    
    required this.label,
    this.status = StatusType.normal,
    this.showIcon = true,
    this.customIcon,super.key,
  });

  Color get _color {
    switch (status) {
      case StatusType.normal:
        return AppColors.success;
      case StatusType.warning:
        return AppColors.warning;
      case StatusType.error:
        return AppColors.error;
      case StatusType.info:
        return AppColors.info;
    }
  }

  Color get _lightColor {
    switch (status) {
      case StatusType.normal:
        return AppColors.successLight;
      case StatusType.warning:
        return AppColors.warningLight;
      case StatusType.error:
        return AppColors.errorLight;
      case StatusType.info:
        return AppColors.infoLight;
    }
  }

  IconData get _icon {
    if (customIcon != null) return customIcon!;
    switch (status) {
      case StatusType.normal:
        return Icons.check_circle_rounded;
      case StatusType.warning:
        return Icons.warning_rounded;
      case StatusType.error:
        return Icons.error_rounded;
      case StatusType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _lightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _icon,
              color: _color,
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}