import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable Lottie loading widget that can be embedded in any widget.
///
/// Use this for loading states throughout the app instead of
/// CircularProgressIndicator for a more polished look.
class LottieLoadingWidget extends StatefulWidget {
  /// The size of the Lottie animation. Defaults to 120.
  final double size;

  /// Whether to repeat the animation. Defaults to true.
  final bool repeat;

  /// Whether to show a semi-transparent background. Defaults to false.
  final bool showBackground;

  /// Optional message to display below the animation.
  final String? message;

  const LottieLoadingWidget({
    super.key,
    this.size = 120,
    this.repeat = true,
    this.showBackground = false,
    this.message,
  });

  @override
  State<LottieLoadingWidget> createState() => _LottieLoadingWidgetState();
}

class _LottieLoadingWidgetState extends State<LottieLoadingWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: Lottie.asset(
            'assets/lottie/sandy.json',
            controller: _controller,
            onLoaded: (composition) {
              _controller.duration = composition.duration;
              if (widget.repeat) {
                _controller.repeat();
              } else {
                _controller.forward();
              }
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (widget.showBackground) {
      return Container(
        color: Colors.black38,
        child: Center(child: content),
      );
    }

    return content;
  }
}

/// A full-screen loading overlay with Lottie animation.
/// 
/// Use this for sync operations that should block user interaction.
class LottieLoadingOverlay extends StatelessWidget {
  /// Optional progress text (e.g., "5 / 10").
  final String? progressText;

  /// Optional progress value (0.0 to 1.0). If provided, shows a progress bar.
  final double? progressValue;

  /// The message to display below the animation.
  final String message;

  const LottieLoadingOverlay({
    required this.message, super.key,
    this.progressText,
    this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 150,
                  height: 150,
                  child: LottieLoadingWidget(
                    size: 150,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 12),
                if (progressValue != null) ...[
                  SizedBox(
                    width: 150,
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (progressText != null) ...[
                  Text(
                    progressText!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Please wait',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
