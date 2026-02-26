// lib/core/widgets/gradient_button.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';


class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? colors;
  final bool isFullWidth;
  
  const GradientButton({
    
    required this.text,super.key,
    this.onPressed,
    this.colors,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final gradientColors = colors ?? [
      AppColors.accentAmber,
      AppColors.primary,
      AppColors.primary.withValues(alpha:0.8),
      AppColors.primary.withValues(alpha:0.4),
      AppColors.accentMint,
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha:0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            width: isFullWidth ? double.infinity : null,
            alignment: Alignment.center,
            child: Text(
              text,
              style: AppTypography.button,
            ),
          ),
        ),
      ),
    );
  }
}