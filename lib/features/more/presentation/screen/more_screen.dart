import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/enums/app_route.dart';
import 'package:church_attendance_app/core/presentation/providers/theme_mode_provider.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../attendance/presentation/screens/attendance_history_screen.dart';

/// More screen with organized sections for user preferences,
/// data management, app information, and account actions.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(isDarkModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    void navigateToHistory() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
      );
    }

    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.more),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
          children: [
            const SizedBox(height: AppDimens.paddingM),

            // ─────────────────────────────────────────────
            // Preferences Section
            // ─────────────────────────────────────────────
            _buildSectionHeader(context, 'Preferences'),
            const SizedBox(height: AppDimens.paddingS),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha:0.5),
                ),
              ),
              child: Column(
                children: [
                  // Dark Mode Toggle
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: colorScheme.primary,
                      ),
                    ),
                    title: const Text('Dark Mode'),
                    subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
                    value: isDarkMode,
                    onChanged: (value) {
                      ref.read(themeModeProvider.notifier).toggleThemeMode();
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  // Settings Navigation
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: colorScheme.secondary,
                      ),
                    ),
                    title: const Text(AppStrings.settings),
                    subtitle: const Text('App settings and preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      AppRoute.settings.navigate(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.paddingL),

            // ─────────────────────────────────────────────
            // Data Management Section
            // ─────────────────────────────────────────────
            _buildSectionHeader(context, 'Data Management'),
            const SizedBox(height: AppDimens.paddingS),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha:0.5),
                ),
              ),
              child: Column(
                children: [
                  // Attendance History
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.accentMint.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: AppColors.accentMint,
                      ),
                    ),
                    title: const Text('Attendance History'),
                    subtitle: const Text('View past attendance records'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: navigateToHistory,
                  ),
                  const Divider(height: 1, indent: 56),
                  // To-do / Scenarios
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppDimens.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.accentPurple,
                      ),
                    ),
                    title: const Text(AppStrings.scenarios),
                    subtitle: const Text('Manage tasks and follow-ups'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      AppRoute.scenarios.navigate(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimens.paddingL),

            // ─────────────────────────────────────────────
            // App Information Section
            // ─────────────────────────────────────────────
            _buildSectionHeader(context, 'App Information'),
            const SizedBox(height: AppDimens.paddingS),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha:0.5),
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppDimens.paddingS),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.accentRose,
                  ),
                ),
                title: const Text(AppStrings.about),
                subtitle: const Text('App info, developer, and support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  AppRoute.about.navigate(context);
                },
              ),
            ),

            const SizedBox(height: AppDimens.paddingXL),

            // ─────────────────────────────────────────────
            // Logout Button
            // ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  // Use global navigator instead of context to avoid
                  // BuildContext lifecycle issues after widget disposal
                  AppRoute.login.navigateAndRemoveUntilWithGlobalKey();
                },
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingL,
                    vertical: AppDimens.paddingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusL),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppDimens.paddingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.paddingS),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
