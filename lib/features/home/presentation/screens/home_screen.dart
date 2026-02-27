import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_attendance_app/core/constants/app_constants.dart';
import 'package:church_attendance_app/core/presentation/widgets/common_widgets.dart';
import 'package:church_attendance_app/core/presentation/widgets/sync_status_indicator.dart';
import 'package:church_attendance_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/providers/contact_count_provider.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_import_overlay.dart';
import 'package:church_attendance_app/features/contacts/presentation/widgets/vcf_import_status_card.dart';
import 'package:church_attendance_app/core/sync/sync_manager_provider.dart';

import '../../../../core/constants/app_strings.dart';

/// Static debug log manager - stores last 100 log lines globally
class DebugLogManager {
  static final List<String> _logs = [];
  static VoidCallback? _onLogAdded;
  static bool _isBuilding = false; // Track if we're in widget build phase
  
  static List<String> get logs => List.unmodifiable(_logs);
  
  static void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logLine = '[$timestamp] $message';
    _logs.add(logLine);
    // Keep only last 100 logs
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    debugPrint('[DEBUG] $logLine');
    // Safeguard: Only trigger callback if not during widget build
    // This prevents "Tried to modify a provider while the widget tree was building" error
    if (!_isBuilding) {
      _onLogAdded?.call();
    } else {
      // Defer the callback to after build completes
      Future.microtask(() => _onLogAdded?.call());
    }
  }
  
  static void clear() {
    _logs.clear();
    _onLogAdded?.call();
  }
  
  static void setListener(VoidCallback callback) {
    _onLogAdded = callback;
  }
  
  static void setBuilding(bool value) {
    _isBuilding = value;
  }
}

/// Notifier to manage debug log trigger count - avoids circular reference (Riverpod 3.x)
class DebugLogsTriggerNotifier extends Notifier<int> {
  @override
  int build() {
    // Set flag to track build phase
    DebugLogManager.setBuilding(true);
    
    DebugLogManager.setListener(() {
      state++;
    });
    
    // Reset flag when build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DebugLogManager.setBuilding(false);
    });
    
    return 0;
  }
}

/// Provider that rebuilds when logs change - uses Notifier to avoid circularity
final debugLogsTriggerProvider = NotifierProvider<DebugLogsTriggerNotifier, int>(() {
  return DebugLogsTriggerNotifier();
});

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
        title:  Text(AppStrings.appName, style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
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
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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

                // Debug log viewer - shows VCF and other logs
                _buildDebugLogViewer(context, ref),
              ],
            ),
          ),
          // Sync overlay - shown while syncing
          // But VCF Import Overlay should take priority
          if (syncStatus.isSyncing)
            Container(
              color: Colors.black38,  // More transparent so VCF overlay shows through
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
                                color: Theme.of(context).colorScheme.onSecondaryFixed.withValues(alpha: 0.3)),textAlign: TextAlign.center,
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
                            color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // VCF Import Overlay - ALWAYS on top, even during sync
          const VcfImportOverlay(),
          // VCF Import Status Card - shows progress/results on home screen
          const VcfImportStatusCard(),
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
                                color: Theme.of(context).colorScheme.onSecondaryFixed.withValues(alpha: 0.3),
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
                              ? Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.3)
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
              error: (_, _) => Text(
                'Unable to load contact count',
                style: TextStyle(color: Colors.red[300]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build debug log viewer widget
  Widget _buildDebugLogViewer(BuildContext context, WidgetRef ref) {
    // Watch the trigger to rebuild when logs change
    ref.watch(debugLogsTriggerProvider);
    final logs = DebugLogManager.logs;
    
    return Card(
      elevation: AppDimens.cardElevation,
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bug_report,
                      size: 20,
                      color: Colors.green[400],
                    ),
                    const SizedBox(width: AppDimens.paddingS),
                    Text(
                      'VCF Debug Logs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white54, size: 18),
                  onPressed: () {
                    DebugLogManager.clear();
                  },
                  tooltip: 'Clear logs',
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No debug logs yet.\nShare a VCF file to see logs here.',
                        style: TextStyle(color: Colors.white38),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        Color textColor = Colors.green[300]!;
                        if (log.contains('ERROR') || log.contains('error')) {
                          textColor = Colors.red;
                        } else if (log.contains('WARNING') || log.contains('warning')) {
                          textColor = Colors.orange;
                        } else if (log.contains('[VCF')) {
                          textColor = Colors.cyan;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

