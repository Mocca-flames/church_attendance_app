

/// Application-wide dimension constants.
abstract final class AppDimens {
  AppDimens._();

  // Padding & Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 20.0;
  static const double radiusCircle = 100.0;

  // Icon sizes
  static const double iconS = 16.0;
  static const double iconM = 20.0;
  static const double iconL = 28.0;
  static const double iconXL = 40.0;
  static const double iconXXL = 60.0;
  static const double iconSplash = 100.0;

  static const double buttonHeight = 50.0;
  static const double buttonHeightSmall = 36.0;

  // Avatar sizes
  static const double avatarS = 24.0;
  static const double avatarM = 36.0;
  static const double avatarL = 48.0;

  // Card
  static const double cardElevation = 2.0;
  static const double cardElevationHigh = 4.0;

  // Grid
  static const double gridAspectRatio = 1.3;
  static const int gridCrossAxisCount = 2;
  static const double gridSpacing = 12.0;

  // Text sizes
  static const double textSizeButton = 16.0;
}

/// Animation duration constants.
abstract final class AppDurations {
  AppDurations._();

  static const Duration splashDelay = Duration(seconds: 1);
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

/// Phone number utility functions for South African numbers.
abstract final class PhoneUtils {
  PhoneUtils._();

  /// Normalizes a South African phone number to +27XXXXXXXXX format.
  /// 
  /// Handles the following formats:
  /// - 0821234567 → +27821234567
  /// - +27821234567 → +27821234567 (unchanged)
  /// - 27821234587 → +27821234567
  /// - +27 82 123 4567 → +27821234567
  /// 
  /// Returns null if the phone number cannot be parsed.
  static String? normalizeSouthAfricanPhone(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    
    // Remove all whitespace and non-digit characters except +
    final String cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    
    // Handle +27 prefix
    if (cleaned.startsWith('+27')) {
      // Already in correct format, just ensure it's digits only
      final digits = cleaned.substring(3).replaceAll(RegExp(r'\D'), '');
      if (digits.length == 9) {
        return '+27$digits';
      }
      return null;
    }
    
    // Handle 27 prefix (without +)
    if (cleaned.startsWith('27') && cleaned.length >= 10) {
      final digits = cleaned.substring(2).replaceAll(RegExp(r'\D'), '');
      if (digits.length == 9) {
        return '+27$digits';
      }
      return null;
    }
    
    // Handle 0 prefix (most common - e.g., 0821234567)
    if (cleaned.startsWith('0') && cleaned.length >= 10) {
      final digits = cleaned.substring(1).replaceAll(RegExp(r'\D'), '');
      if (digits.length == 9) {
        return '+27$digits';
      }
      return null;
    }
    
    // If it's exactly 9 digits, assume it's without prefix
    final digitsOnly = cleaned.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 9) {
      return '+27$digitsOnly';
    }
    
    return null;
  }

  /// Formats a +27XXXXXXXXX phone number for display as 0XX XXX XXXX.
  /// 
  /// Example: +27821234567 → 082 123 4567
  static String formatForDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    
    // Normalize first
    final normalized = normalizeSouthAfricanPhone(phone);
    if (normalized == null) return phone;
    
    // Remove +27 prefix and format
    final digits = normalized.substring(3);
    if (digits.length == 9) {
      return '0${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
    }
    
    return phone;
  }
}


  
