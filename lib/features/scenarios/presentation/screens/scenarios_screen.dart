import 'package:flutter/material.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';

/// Placeholder screen for Scenarios feature.
/// Shows "Coming Soon" message until the feature is implemented.
class ScenariosScreen extends StatelessWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.scenarios),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.checklist,
              size: AppDimens.iconXXL,
              color: AppColors.scenariosColor,
            ),
            const SizedBox(height: AppDimens.paddingL),
            Text(
              AppStrings.scenarios,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              AppStrings.comingSoon,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
