import 'package:church_attendance_app/core/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/validators/form_validators.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/core/presentation/widgets/common_widgets.dart';
import 'package:church_attendance_app/core/enums/user_role.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/constants/app_strings.dart';

/// Registration screen for new users.
/// Provides form validation and role selection.
/// Follows Clean Architecture with separated concerns.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final UserRole _selectedRole = UserRole.servant;
  GradientButtonState _buttonState = GradientButtonState.idle;
  bool _loginInitiated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  /// Toggle confirm password visibility
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _obscureConfirmPassword = !_obscureConfirmPassword;
    });
  }

  /// Handle registration form submission
  Future<void> _handleRegister() async {
    // Clear previous errors
    ref.read(authProvider.notifier).clearError();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _loginInitiated = true;
        _buttonState = GradientButtonState.loading;
      });

      final success = await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole.backendValue,
          );

      if (!success && mounted) {
        setState(() {
          _loginInitiated = false;
          _buttonState = GradientButtonState.error;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _buttonState = GradientButtonState.idle;
            });
          }
        });
      } else if (success && mounted) {
        // Navigation happens directly here, no state change to avoid rebuild
        AppRoute.main.navigateAndRemoveUntil(context);
      }
    }
  }

  /// Navigate to login screen
  void _navigateToLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final authError = ref.watch(authErrorProvider);
    final isLoading = ref.watch(authLoadingProvider);

    // Determine button state - keep loading if login was initiated
    GradientButtonState buttonState;
    if (_buttonState == GradientButtonState.error) {
      buttonState = GradientButtonState.error;
    } else if (isLoading || _loginInitiated) {
      buttonState = GradientButtonState.loading;
    } else {
      buttonState = GradientButtonState.idle;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createAccount),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo/Title
                Center(child: Image.asset('assets/logo.png', width: 120, height: 120)),
                const SizedBox(height: AppDimens.paddingXL),

                // Form fields
                Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: AppStrings.email,
                          hintText: AppStrings.enterEmail,
                          prefixIcon: Icon(Icons.email_outlined),
                        ).applyDefaults(Theme.of(context).inputDecorationTheme),
                        validator: FormValidators.email,
                      ),
                      const SizedBox(height: AppDimens.paddingM),

                      // Password field
                      PasswordField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onToggleVisibility: _togglePasswordVisibility,
                        validator: FormValidators.password,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppDimens.paddingM),

                      // Confirm Password field
                      PasswordField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        onToggleVisibility: _toggleConfirmPasswordVisibility,
                        validator: (value) => FormValidators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleRegister(),
                        labelText: AppStrings.confirmPassword,
                        hintText: AppStrings.reEnterPassword,
                      ),
                      const SizedBox(height: AppDimens.paddingS),

                      // Error message
                      if (authError != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppDimens.paddingM),
                          child: AppErrorContainer(
                            message: authError,
                            onDismiss: () =>
                                ref.read(authProvider.notifier).clearError(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDimens.paddingXL),
                const SizedBox(height: AppDimens.paddingXL),

                // Register button - outside of Form for visual separation
                GradientButton(
                  onPressed: _handleRegister,
                  state: buttonState,
                  isFullWidth: true,
                  text: AppStrings.register,
                  errorText: 'Registration Failed',
                ),
                const SizedBox(height: AppDimens.paddingL),

                // Login link
                AuthLinkRow(
                  questionText: AppStrings.alreadyHaveAccount,
                  linkText: AppStrings.signInLink,
                  onLinkPressed: _navigateToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
