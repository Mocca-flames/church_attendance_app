import 'package:church_attendance_app/core/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/validators/form_validators.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/core/presentation/widgets/common_widgets.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/constants/app_strings.dart';

/// Login screen for user authentication.
/// Provides form validation and error handling.
/// Follows Clean Architecture with separated concerns.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  GradientButtonState _buttonState = GradientButtonState.idle;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Toggle password visibility
  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  /// Handle login form submission
  Future<void> _handleLogin() async {
    // Clear previous errors
    ref.read(authProvider.notifier).clearError();

    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (success && mounted) {
        AppRoute.main.navigateReplacement(context);
      } else if (!success && mounted) {
        // Login failed - show error state
        setState(() {
          _buttonState = GradientButtonState.error;
        });
        // Revert to idle after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _buttonState = GradientButtonState.idle;
            });
          }
        });
      }
    }
  }

  /// Navigate to sign up screen
  void _navigateToSignUp() {
    AppRoute.signIn.navigate(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    final authError = ref.watch(authErrorProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    
    // Determine button state
    GradientButtonState buttonState;
    if (_buttonState == GradientButtonState.error) {
      buttonState = GradientButtonState.error;
    } else if (isAuthenticated) {
      buttonState = GradientButtonState.success;
    } else if (isLoading) {
      buttonState = GradientButtonState.loading;
    } else {
      buttonState = GradientButtonState.idle;
    }
    

    // Listen for auth state changes and navigate to home if authenticated
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        AppRoute.main.navigateReplacement(context);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo/Title
                  const AppLogo(
                    title: AppStrings.appName,
                    subtitle: AppStrings.signInToContinue,
                    iconSize: AppDimens.iconXXL,
                  ),
                  const SizedBox(height: AppDimens.paddingXL),

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
                    onFieldSubmitted: (_) => _handleLogin(),
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
                  const SizedBox(height: AppDimens.paddingL),

                  // Login button
                  GradientButton(
                    onPressed: _handleLogin,
                    state: buttonState,
                    isFullWidth: true,
                    text: AppStrings.signIn,
                    errorText: 'Login Failed',
                  ),
                  const SizedBox(height: AppDimens.paddingL),

                  // Register link
                  AuthLinkRow(
                    questionText: AppStrings.dontHaveAccount,
                    linkText: AppStrings.signUpLink,
                    onLinkPressed: _navigateToSignUp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
