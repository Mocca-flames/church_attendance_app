// lib/core/widgets/circular_progress_card.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';


class CircularProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double percentage; // 0.0 to 1.0
  final Color progressColor;
  final Color? backgroundColor;
  final String? detailsText;
  final VoidCallback? onDetailsTap;
  
  const CircularProgressCard({
   
    required this.title,
    required this.subtitle,
    required this.percentage,
    this.progressColor = AppColors.primary,
    this.backgroundColor,
    this.detailsText,
    this.onDetailsTap, 
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral200.withValues(alpha:0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h4,
                    ),
                    if (detailsText != null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: onDetailsTap,
                        child: Text(
                          detailsText!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildCircularProgress(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: AppTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularProgress() {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: 6,
            backgroundColor: AppColors.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          Center(
            child: Text(
              '${(percentage * 100).toInt()}%',
              style: AppTypography.labelLarge.copyWith(
                color: progressColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}