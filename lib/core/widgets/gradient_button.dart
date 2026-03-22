// lib/core/widgets/gradient_button.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Button states for GradientButton
enum GradientButtonState {
  /// Normal idle state - shows text
  idle,
  /// Loading state - shows spinner animation
  loading,
  /// Success state - shows checkmark
  success,
  /// Error state - shows error icon
  error,
}

class GradientButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? colors;
  final bool isFullWidth;
  final GradientButtonState state;
  final bool repeat;
  final String? successText;
  final String? errorText;
  
  const GradientButton({
    required this.text,
    super.key,
    this.onPressed,
    this.colors,
    this.isFullWidth = true,
    this.state = GradientButtonState.idle,
    this.repeat = true,
    this.successText,
    this.errorText,
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
    // Handle state transitions
    if (widget.state == GradientButtonState.loading && oldWidget.state != GradientButtonState.loading) {
      // Animation will start in onLoaded callback after duration is set
    } else if (widget.state != GradientButtonState.loading && oldWidget.state == GradientButtonState.loading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get gradient colors based on state
  List<Color> _getGradientColors() {
    switch (widget.state) {
      case GradientButtonState.loading:
        return [
          Colors.grey.shade400,
          const Color.fromARGB(255, 16, 27, 32).withValues(alpha:0.4),
          AppColors.primary,
        ];
      case GradientButtonState.success:
        return [
          Colors.green.shade400,
          Colors.green,
          Colors.green.shade600,
        ];
      case GradientButtonState.error:
        return [
          Colors.red.shade400,
          Colors.red,
          Colors.red.shade600,
        ];
      case GradientButtonState.idle:
      return widget.colors ?? [
          AppColors.accentAmber,
          AppColors.primary,
          AppColors.primary.withValues(alpha:0.8),
          AppColors.primary.withValues(alpha:0.4),
          AppColors.accentMint,
        ];
    }
  }

  /// Get the icon for the current state
  IconData? _getStateIcon() {
    switch (widget.state) {
      case GradientButtonState.success:
        return Icons.check;
      case GradientButtonState.error:
        return Icons.close;
      default:
        return null;
    }
  }

  /// Get the display text for the current state
  String? _getDisplayText() {
    switch (widget.state) {
      case GradientButtonState.success:
        return widget.successText ?? widget.text;
      case GradientButtonState.error:
        return widget.errorText ?? widget.text;
      default:
        return widget.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || 
        widget.state == GradientButtonState.loading ||
        widget.state == GradientButtonState.success;
    
    final gradientColors = _getGradientColors();
    final stateIcon = _getStateIcon();
    final displayText = _getDisplayText();
    final isStateWithIcon = widget.state == GradientButtonState.success || 
                           widget.state == GradientButtonState.error;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: widget.state == GradientButtonState.idle
            ? [
                BoxShadow(
                  color: gradientColors.last.withValues(alpha:0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: widget.state != GradientButtonState.idle
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            height: widget.state != GradientButtonState.idle ? 56 : null,
            width: widget.isFullWidth ? double.infinity : null,
            alignment: Alignment.center,
            child: _buildContent(stateIcon, displayText, isStateWithIcon),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(IconData? stateIcon, String? displayText, bool isStateWithIcon) {
    switch (widget.state) {
      case GradientButtonState.loading:
        return SizedBox(
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
              animate: true,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                if (widget.state == GradientButtonState.loading) {
                  if (widget.repeat) {
                    _controller.repeat();
                  } else {
                    _controller.forward();
                  }
                }
              },
            ),
          ),
        );
      case GradientButtonState.success:
      case GradientButtonState.error:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              stateIcon,
              color: Colors.white,
              size: 28,
            ),
            if (displayText != null) ...[
              const SizedBox(width: 8),
              Text(
                displayText,
                style: AppTypography.button.copyWith(color: Colors.white),
              ),
            ],
          ],
        );
      case GradientButtonState.idle:
      return Text(
          widget.text,
          style: AppTypography.button,
        );
    }
  }
}
