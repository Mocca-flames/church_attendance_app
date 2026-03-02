import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:logger/logger.dart';

/// Centralized service for haptic feedback across the app.
///
/// Uses the `haptic_feedback` package which provides better cross-platform
/// support than Flutter's built-in HapticFeedback.
///
/// Usage:
/// ```dart
/// await HapticService.success();
/// await HapticService.medium();
/// await HapticService.error();
/// ```
class HapticService {
  static final Logger _logger = Logger();

  /// Check if the device can vibrate
  static Future<bool> canVibrate() async {
    try {
      return await Haptics.canVibrate();
    } catch (e) {
      _logger.w('Failed to check haptic capability: $e');
      return false;
    }
  }

  /// Success feedback - use for successful operations
  static Future<void> success() async {
    await _vibrate(HapticsType.success);
  }

  /// Warning feedback - use for warnings or cautions
  static Future<void> warning() async {
    await _vibrate(HapticsType.warning);
  }

  /// Error feedback - use for errors or failures
  static Future<void> error() async {
    await _vibrate(HapticsType.error);
  }

  /// Light impact - subtle feedback
  static Future<void> light() async {
    await _vibrate(HapticsType.light);
  }

  /// Medium impact - standard feedback (most common)
  static Future<void> medium() async {
    await _vibrate(HapticsType.medium);
  }

  /// Heavy impact - strong feedback
  static Future<void> heavy() async {
    await _vibrate(HapticsType.heavy);
  }

  /// Rigid impact - sharp feedback
  static Future<void> rigid() async {
    await _vibrate(HapticsType.rigid);
  }

  /// Soft impact - gentle feedback
  static Future<void> soft() async {
    await _vibrate(HapticsType.soft);
  }

  /// Selection feedback - use for selection changes
  static Future<void> selection() async {
    await _vibrate(HapticsType.selection);
  }

  /// Generic vibrate with specific type
  static Future<void> vibrate(HapticsType type) async {
    await _vibrate(type);
  }

  /// Internal method to handle vibration with error handling
  static Future<void> _vibrate(HapticsType type) async {
    try {
      await Haptics.vibrate(type);
    } catch (e) {
      _logger.w('Haptic feedback failed: $e');
    }
  }
}
