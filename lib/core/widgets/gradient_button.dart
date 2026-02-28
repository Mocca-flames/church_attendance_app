// lib/core/widgets/gradient_button.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? colors;
  final bool isFullWidth;
  final bool isLoading;
  final bool repeat;
  
  const GradientButton({
    required this.text,super.key,
    this.onPressed,
    this.colors,
    this.isFullWidth = true,
    this.isLoading = false,
    this.repeat = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(GradientButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Duration is set in onLoaded callback - don't repeat here
    if (widget.isLoading && !oldWidget.isLoading) {
      // Animation will start in onLoaded callback after duration is set
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    
    final gradientColors = widget.isLoading
        ? [
            Colors.grey.shade400,
            const Color.fromARGB(255, 16, 27, 32).withValues(alpha:0.4),
            AppColors.primary,
          ]
        : widget.colors ?? [
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
        boxShadow: widget.isLoading
            ? []
            : [
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
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: widget.isLoading
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 16
                ),
            height: widget.isLoading ? 56 : null,
            width: widget.isFullWidth ? double.infinity : null,
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: 56,
                    height: 56,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                      child: Lottie.asset(
                        'assets/lottie/particle.json',
                        controller: _controller,
                        fit: BoxFit.contain,
                        animate: widget.isLoading,
                        onLoaded: (composition) {
                          _controller.duration = composition.duration;
                          if (widget.isLoading) {
                            if (widget.repeat) {
                              _controller.repeat();
                            } else {
                              _controller.forward();
                            }
                          }
                        },
                      ),
                    ),
                  )
                : Text(
                    widget.text,
                    style: AppTypography.button,
                  ),
          ),
        ),
      ),
    );
  }
}
