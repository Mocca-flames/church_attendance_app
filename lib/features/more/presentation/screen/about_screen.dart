import 'package:flutter/material.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/constants/app_strings.dart';
import 'package:church_attendance_app/core/widgets/gradient_background.dart';

/// About screen displaying app information and developer details.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DynamicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.about),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimens.paddingL),
              
              // App Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppDimens.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha:0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.church,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingL),
              
              // App Name
              Text(
                AppStrings.appName,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingXS),
              
              // App Tagline
              Text(
                AppStrings.appTagline,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingXS),
              
              // Version
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM,
                  vertical: AppDimens.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppDimens.radiusM),
                ),
                child: Text(
                  AppStrings.appVersion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingXL),
              
              // App Description Card
              _buildSectionCard(
                context,
                title: 'About the App',
                icon: Icons.info_outline,
                child: Text(
                  AppStrings.appDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingL),
              
              // Key Features Card
              _buildSectionCard(
                context,
                title: AppStrings.keyFeatures,
                icon: Icons.star_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem(context, AppStrings.featureAttendance),
                    _buildFeatureItem(context, AppStrings.featureContacts),
                    _buildFeatureItem(context, AppStrings.featureScenarios),
                    _buildFeatureItem(context, AppStrings.featureSync),
                    _buildFeatureItem(context, AppStrings.featureReports),
                  ],
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingL),
              
              // Developer Info Card
              _buildSectionCard(
                context,
                title: AppStrings.developedBy,
                icon: Icons.code,
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.secondary,
                            colorScheme.primary,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'MS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppDimens.paddingM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.developerName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.developerTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingL),
              
              // Support Section
              _buildSectionCard(
                context,
                title: AppStrings.support,
                icon: Icons.help_outline,
                child: Column(
                  children: [
                    _buildSupportTile(
                      context,
                      icon: Icons.email_outlined,
                      title: AppStrings.contactSupport,
                      onTap: () {
                        // TODO: Implement contact support
                        _showComingSoonSnackBar(context);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSupportTile(
                      context,
                      icon: Icons.privacy_tip_outlined,
                      title: AppStrings.privacyPolicy,
                      onTap: () {
                        // TODO: Implement privacy policy
                        _showComingSoonSnackBar(context);
                      },
                    ),
                    const Divider(height: 1),
                    _buildSupportTile(
                      context,
                      icon: Icons.description_outlined,
                      title: AppStrings.termsOfService,
                      onTap: () {
                        // TODO: Implement terms of service
                        _showComingSoonSnackBar(context);
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppDimens.paddingXL),
              
              // Copyright
              Text(
                '© 2025 ${AppStrings.appName}. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha:0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppDimens.paddingL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha:0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Divider(height: AppDimens.paddingL),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingXS),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSupportTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: colorScheme.primary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onTap: onTap,
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.comingSoon),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
