import 'package:flutter/material.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import '../../constants/app_strings.dart';

/// Reusable error container widget for displaying error messages.
class AppErrorContainer extends StatelessWidget {
  const AppErrorContainer({
    required this.message,
    this.onDismiss,
    super.key,
  });

  /// The error message to display
  final String message;

  /// Optional callback when error is dismissed
  final VoidCallback? onDismiss;

  

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onError.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: Theme.of(context).colorScheme.onError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: AppDimens.iconL,
          ),
          const SizedBox(width: AppDimens.paddingS),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.error,
                size: AppDimens.iconM,
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Reusable action card widget for home screen grid.
class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    super.key,
  });

  /// The icon to display
  final IconData icon;

  /// The title text
  final String title;

  /// The color for the icon background
  final Color color;

  /// Callback when card is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimens.cardElevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: AppDimens.iconL,
                ),
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable loading indicator button.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    required this.onPressed,
    required this.isLoading,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    super.key,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Whether the button is in loading state
  final bool isLoading;

  /// The button label text
  final String label;

  /// Optional background color
  final Color? backgroundColor;

  /// Optional foreground color
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: AppDimens.iconM,
                width: AppDimens.iconM,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: AppDimens.textSizeButton,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

/// Reusable password field with visibility toggle.
class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.controller,
    required this.obscureText,
    required this.onToggleVisibility,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction,
    this.labelText,
    this.hintText,
    super.key,
  });

  /// Text editing controller
  final TextEditingController controller;

  /// Whether to obscure the text
  final bool obscureText;

  /// Callback to toggle visibility
  final VoidCallback onToggleVisibility;

  /// Optional validator function
  final String? Function(String?)? validator;

  /// Optional submit callback
  final void Function(String)? onFieldSubmitted;

  /// Optional text input action
  final TextInputAction? textInputAction;

  /// Optional label text
  final String? labelText;

  /// Optional hint text
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      textInputAction: textInputAction ?? TextInputAction.done,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText ?? AppStrings.password,
        hintText: hintText ?? AppStrings.enterPassword,
        prefixIcon: const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: onToggleVisibility,
        ),
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
  }
}

/// Reusable auth link row widget.
class AuthLinkRow extends StatelessWidget {
  const AuthLinkRow({
    required this.questionText,
    required this.linkText,
    required this.onLinkPressed,
    super.key,
  });

  /// The question text before the link
  final String questionText;

  /// The link text
  final String linkText;

  /// Callback when link is pressed
  final VoidCallback onLinkPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          questionText,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        TextButton(
          onPressed: onLinkPressed,
          child: Text(linkText),
        ),
      ],
    );
  }
}

/// Reusable app logo widget for auth screens.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    this.iconSize,
  });

  /// Optional icon (defaults to church icon)
  final IconData? icon;

  /// Optional title text
  final String? title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional icon size
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon ?? Icons.church,
          size: iconSize ?? AppDimens.iconXXL,
          color: Theme.of(context).colorScheme.primary,
        ),
        if (title != null) ...[
          const SizedBox(height: AppDimens.paddingM),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: AppDimens.paddingS),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

/// Reusable role badge widget.
class RoleBadge extends StatelessWidget {
  const RoleBadge({
    required this.displayName,
    required this.icon,
    required this.color,
    super.key,
  });

  /// The role display name
  final String displayName;

  /// The role icon
  final IconData icon;

  /// The role color
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingM,
        vertical: AppDimens.paddingS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimens.iconS,
            color: color,
          ),
          const SizedBox(width: AppDimens.paddingXS),
          Text(
            displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
