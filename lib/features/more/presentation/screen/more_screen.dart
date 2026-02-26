import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/core/presentation/providers/theme_mode_provider.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// More screen with navigation options for Scenarios and Settings.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.more)),

      body: ListView(
        children: [
          const SizedBox(height: AppDimens.paddingM),
          // Dark Mode toggle
          SwitchListTile(
            secondary: Icon(
              isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
            value: isDarkMode,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).toggleThemeMode();
            },
          ),
          const Divider(),
          // Scenarios navigation option
          ListTile(
            leading: Icon(
              Icons.checklist,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text(AppStrings.scenarios),
            subtitle: const Text('Manage tasks and follow-ups'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppRoute.scenarios.navigate(context);
            },
          ),
          const Divider(),
          // Settings navigation option
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.primary),
            title: const Text(AppStrings.settings),
            subtitle: const Text('App preferences and configuration'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              AppRoute.settings.navigate(context);
            },
          ),
          const Divider(),
          const SizedBox(height: AppDimens.paddingXL),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
            child: ElevatedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  AppRoute.login.navigateAndRemoveUntil(context);
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingL,
                  vertical: AppDimens.paddingM,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingXL),
        ],
      ),
    );
  }
}
