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
    this.gradientColors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base layer: top-to-bottom neutral fade (gives the "grey/white" grounding)
        Container(
          decoration: BoxDecoration(
            gradient: useGradient
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors ??
                        (isDark
                            ? AppColors.backgroundGradientDark
                            : AppColors.backgroundGradientLight),
                    stops: const [0.0, 1.0],
                  )
                : null,
            color: useGradient
                ? null
                : (isDark
                    ? AppColors.darkBackgroundPrimary
                    : AppColors.backgroundPrimary),
          ),
        ),

        // Accent layer: radial cyan glow anchored bottom-left
        // Subtle but visible — adds depth without distracting
        if (useGradient && isDark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, 1.2), // bottom-left bleed
                  radius: 1.1,
                  colors: [
                    const Color(0xFF164E63).withValues(alpha:0.45), // Cyan 900
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

        // Second accent: top-right whisper of cyan (balance)
        if (useGradient && isDark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -0.8), // top-right
                  radius: 0.7,
                  colors: [
                    const Color.fromARGB(122, 15, 23, 42).withValues(alpha:0.6), // Slate 900 cool tint
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

        // LIGHT MODE: Subtle cyan accent at bottom-left
        if (useGradient && !isDark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, 1.3), // bottom-left
                  radius: 1.2,
                  colors: [
                    const Color(0xFF06B6D4).withValues(alpha:0.15), // Cyan 500 light
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

        // LIGHT MODE: Subtle warm accent at top-right for balance
        if (useGradient && !isDark)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.0, -0.9), // top-right
                  radius: 0.8,
                  colors: [
                    const Color(0xFFF0F9FF).withValues(alpha:0.5), // Very light cyan
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

        // Content on top
        child,
      ],
    );
  }
}