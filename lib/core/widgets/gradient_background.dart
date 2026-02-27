// lib/core/widgets/gradient_background.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';


class DynamicBackground extends StatelessWidget {
  final Widget child;
  final bool useGradient;
  final List<Color>? gradientColors;
  
  const DynamicBackground({
    
    required this.child,
    this.useGradient = true,
    this.gradientColors,super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: useGradient
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? AppColors.backgroundGradientLight,
              )
            : null,
        color: useGradient ? null : AppColors.backgroundPrimary,
      ),
      child: child,
    );
  }
}