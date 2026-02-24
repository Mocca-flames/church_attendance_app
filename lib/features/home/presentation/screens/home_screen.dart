import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/presentation/widgets/common_widgets.dart';
import 'package:church_attendance_app/core/presentation/widgets/sync_status_indicator.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_count_provider.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

/// Home screen - main dashboard after authentication.
/// Shows user info and provides navigation to other features.
/// Follows Clean Architecture with separated concerns.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialSyncDone = false;

  @override
  void initState() {
    super.initState();
    // Trigger sync on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerInitialSync();
    });
  }

  /// Trigger initial sync if not done yet
  Future<void> _triggerInitialSync() async {
    if (_isInitialSyncDone) return;
    
    _isInitialSyncDone = true;
    
    try {
      // First, sync any pending offline items (attendance, contacts) to server
      await ref.read(syncStatusProvider.notifier).syncAll();
      
      // Then pull fresh contacts from server
      final needsSync = await ref.read(contactsNeedSyncProvider.future);
      if (needsSync) {
        await ref.read(syncStatusProvider.notifier).pullContacts(forceFullSync: true);
        // Refresh contact count display
        ref.invalidate(offlineContactCountProvider);
        ref.invalidate(offlineContactStoreInfoProvider);
      }
    } catch (e) {
      // Sync failed - continue anyway
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Sync status indicator in app bar
          const Padding(
            padding: EdgeInsets.only(right: AppDimens.paddingS),
            child: SyncStatusIndicatorCompact(),
          ),
          // User avatar with role badge
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppDimens.paddingS),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome card
                _buildWelcomeCard(context, user),
                const SizedBox(height: AppDimens.paddingL),

                // Offline data status card
                _buildOfflineDataCard(context, ref),
                const SizedBox(height: AppDimens.paddingL),

                // Quick actions
                Text(
                  AppStrings.quickActions,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          // Sync overlay - shown while syncing
          if (syncStatus.isSyncing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(AppDimens.paddingXL),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimens.paddingXL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (syncStatus.totalProgress > 0) ...[
                          // Show progress bar for known total
                          SizedBox(
                            width: 200,
                            child: LinearProgressIndicator(
                              value: syncStatus.progressPercent / 100,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: AppDimens.paddingM),
                          Text(
                            '${syncStatus.currentProgress} / ${syncStatus.totalProgress}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (syncStatus.progressMessage != null) ...[
                            const SizedBox(height: AppDimens.paddingS),
                            Text(
                              syncStatus.progressMessage!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ] else ...[
                          // Show indeterminate progress
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppDimens.paddingM),
                          Text(
                            'Syncing contacts...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        const SizedBox(height: AppDimens.paddingS),
                        Text(
                          'Please wait',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build the welcome card widget
  Widget _buildWelcomeCard(BuildContext context, dynamic user) {
    return Card(
      elevation: AppDimens.cardElevationHigh,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.church,
                  size: AppDimens.iconXL,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppDimens.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.welcome,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (user != null)
                        Text(
                          user.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (user != null) ...[
              const SizedBox(height: AppDimens.paddingM),
              RoleBadge(
                displayName: user.role.displayName,
                icon: user.role.icon,
                color: user.role.color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the offline data status card widget
  Widget _buildOfflineDataCard(BuildContext context, WidgetRef ref) {
    final contactStoreInfo = ref.watch(offlineContactStoreInfoProvider);

    return Card(
      elevation: AppDimens.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.offline_bolt,
                  size: 20,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: AppDimens.paddingS),
                Text(
                  'Offline Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
            contactStoreInfo.when(
              data: (info) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.displayText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: info.totalCount > 0
                              ? AppColors.textSecondary
                              : Colors.orange,
                        ),
                  ),
                  if (info.totalCount > 0)
                    Text(
                      'Ready for offline search',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                ],
              ),
              loading: () => const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppDimens.paddingS),
                  Text('Loading...'),
                ],
              ),
              error: (_, __) => Text(
                'Unable to load contact count',
                style: TextStyle(color: Colors.red[300]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
