import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/constants/app_strings.dart';

/// Splash screen that handles initial authentication check.
/// Uses Riverpod for auth state management.
/// Follows Clean Architecture with separated concerns.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay slightly to allow Riverpod to initialize
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  /// Check authentication status and navigate accordingly
  Future<void> _checkAuth() async {
    // Wait for splash animation
    await Future.delayed(AppDurations.splashDelay);

    // Check auth status using Riverpod
    await ref.read(authProvider.notifier).checkAuthStatus();

    // Get auth state
    final authState = ref.read(authProvider);

    if (mounted) {
      final nextRoute = AppRoute.getInitialRoute(
        isAuthenticated: authState.isAuthenticated,
      );
      nextRoute.navigateReplacement(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.church,
              size: AppDimens.iconSplash,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              AppStrings.appTagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingXXL),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
