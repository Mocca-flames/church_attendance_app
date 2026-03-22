// lib/core/widgets/alert_banner.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';


class AlertBanner extends StatelessWidget {
  final String message;
  final AlertType type;
  final VoidCallback? onActionTap;
  final String? actionText;
  
  const AlertBanner({
    
    required this.message,
    this.type = AlertType.warning,
    this.onActionTap,
    this.actionText,super.key,
  });

  Color get _backgroundColor {
    switch (type) {
      case AlertType.error:
        return AppColors.errorLight;
      case AlertType.warning:
        return AppColors.warningLight;
      case AlertType.success:
        return AppColors.successLight;
      case AlertType.info:
        return AppColors.infoLight;
    }
  }

  Color get _iconColor {
    switch (type) {
      case AlertType.error:
        return AppColors.error;
      case AlertType.warning:
        return AppColors.warning;
      case AlertType.success:
        return AppColors.success;
      case AlertType.info:
        return AppColors.info;
    }
  }

  IconData get _icon {
    switch (type) {
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _iconColor.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _icon,
            color: _iconColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.neutral800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionText != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: _iconColor,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                actionText!,
                style: AppTypography.labelMedium,
              ),
            ),
        ],
      ),
    );
  }
}

enum AlertType {
  error,
  warning,
  success,
  info,
}