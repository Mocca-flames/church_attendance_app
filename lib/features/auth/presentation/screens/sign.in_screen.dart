import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/validators/form_validators.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/core/presentation/widgets/common_widgets.dart';
import 'package:church_attendance_app/core/enums/user_role.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/constants/app_colors.dart';
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
  UserRole _selectedRole = UserRole.servant;

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
      final success = await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole.backendValue,
          );

      if (success && mounted) {
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
    final authState = ref.watch(authProvider);
    final authError = ref.watch(authErrorProvider);

    // Listen for auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        AppRoute.main.navigateAndRemoveUntil(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createAccount),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
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
                    icon: Icons.person_add,
                    title: AppStrings.register,
                    subtitle: AppStrings.createYourAccount,
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
                      border: OutlineInputBorder(),
                    ),
                    validator: FormValidators.email,
                  ),
                  const SizedBox(height: AppDimens.paddingM),

                  // Role dropdown
                  DropdownButtonFormField<UserRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: AppStrings.role,
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(role.icon, size: AppDimens.iconM, color: role.color),
                            const SizedBox(width: AppDimens.paddingS),
                            Text(role.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppDimens.paddingS),
                  Text(
                    AppStrings.selectRole,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
                  const SizedBox(height: AppDimens.paddingL),

                  // Register button
                  LoadingButton(
                    onPressed: _handleRegister,
                    isLoading: authState.isLoading,
                    label: AppStrings.createAccount,
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
      ),
    );
  }
}
