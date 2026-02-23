import 'package:church_attendance_app/core/constants/app_constants.dart';

/// Form validation utilities for authentication forms.
/// Centralizes validation logic for reusability.
abstract final class FormValidators {
  FormValidators._();

  /// Email regex pattern
  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  /// Minimum password length
  static const int minPasswordLength = 6;

  /// Validate email field
  /// Returns null if valid, error message if invalid
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }
    if (!_emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Validate password field
  /// Returns null if valid, error message if invalid
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }
    if (value.length < minPasswordLength) {
      return AppStrings.passwordTooShort;
    }
    return null;
  }

  /// Validate confirm password field
  /// Returns null if valid, error message if invalid
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  /// Validate email with custom error message
  static String? emailWithMessage(String? value, String customMessage) {
    final result = email(value);
    return result ?? customMessage;
  }

  /// Validate password with custom error message
  static String? passwordWithMessage(String? value, String customMessage) {
    final result = password(value);
    return result ?? customMessage;
  }
}

/// Extension to easily use validators with TextFormField
extension FormValidatorsExtension on String? {
  /// Validate as email
  String? get isValidEmail => FormValidators.email(this);

  /// Validate as password
  String? get isValidPassword => FormValidators.password(this);

  /// Validate as confirm password against provided password
  String? isValidConfirmPassword(String password) =>
      FormValidators.confirmPassword(this, password);
}
